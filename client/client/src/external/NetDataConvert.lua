
local function LenArrayRead(LenArray, reader) -- 1维数组转多维数组
	local function reduce(LenArray, ret, reader, _index)
		local is_val = _index >= #LenArray
		for i=1,LenArray[_index] do
			if( is_val )then
				ret[i] = reader()
			else
				if not ret[i] then
					ret[i]={}
				end
				reduce(LenArray, ret[i], reader, _index+1)
			end
		end
	end
	local ret={}
	reduce(LenArray, ret, reader, 1)
	return ret
end

local function LenFieldFormat(src)
	if type(src)=='table' and #src>0 then
		return src
	elseif type(src)=='number' then
		return {src}
	else
		return nil
	end
end
local function LenArrayToSum(src)
	src = LenFieldFormat(src);
	if src and #src>0 then	
		local sum = src[1]
		for i=2,#src do
			sum = sum * src[i]
		end
		return sum, true
	end
	return 1, false
end

local function LenArrayToVec1(LenArray, val) -- 多维数组转1维数组
	local function reduce(val, LenArray, ret, _index)
		local is_val = _index >= #LenArray
		for i=1,LenArray[_index] do
			assert( type(val[i]) ~= 'nil', 'array index('..i .. '/'.. LenArray[_index] ..') empty'  )
			if( is_val )then
				table.insert(ret, val[i]);
			else
				reduce(val[i], LenArray, ret, _index+1)
			end
		end
	end
	local ret={}
	reduce(val, LenArray, ret, 1)
	return ret
end
-----


local function TypeData_getsize(declare, TypeData_typemap, _sizeCache)
	---
	assert(declare and TypeData_typemap)
	
	if not _sizeCache then
		_sizeCache={}
	end
	
	local buffSize = 0;
	for k,v in pairs(declare) do
		assert(v and v['t']);
		if type(v.t) == 'table' or v['d'] then
			local sub = v.d or v.t
			assert(sub and #sub>0, 'type declare subtype empty name=>'..v['k'])
			if not _sizeCache[ sub ] then
				_sizeCache[ sub ] = 1 -- 防止互相引用
				_sizeCache[ sub ] = TypeData_getsize(sub, TypeData_typemap, _sizeCache)
			end
			local len = _sizeCache[ sub ] * (v['s'] or 1) * LenArrayToSum(v['l'])
			buffSize = buffSize + len
		else
			local keyType = string.lower(v["t"]);
			local desc = TypeData_typemap[keyType];
			assert(desc and desc.len, "type declare invalid: name===>" .. v['k']);
			if keyType == 'string' then
				assert( v['s'] or LenArrayToSum(v['l'])>1 )
			end
			local len = desc.len * (v['s'] or 1) * LenArrayToSum(v['l'])
			buffSize = buffSize + len
		end
	end
	return buffSize;
end

local function TypeData_write(declare, TypeData_typemap, srcData, obj)
	--
	assert(declare and TypeData_typemap and srcData)
	assert(obj)
	for k,v in pairs(declare) do
		assert( v and v['t'] and v['k'] );
		local srcVal = srcData[v.k];
		assert(type(srcVal)~= 'nil', "declare field value empty: { " .. v['k'] .. '=nil }')
		
		local LenArray = LenFieldFormat(v.l)
		if LenArray and #LenArray>0 then
			srcVal = LenArrayToVec1(LenArray, srcVal)
		else
			srcVal = {srcVal}
		end
		if type(v.t) == 'table' or v['d'] then
			local sub = v.d or v.t
			assert(sub and #sub>0, 'type declare subtype empty name=>'..v['k'])
			for i=1, #srcVal do
				assert(type(srcVal[i])~= 'nil', "declare field value empty: { " .. v['k'] .. '['..i..']=nil }')
				TypeData_write(sub, TypeData_typemap, srcVal[i], obj)
			end
		else
			local keyType = string.lower(v["t"]);
			local desc = TypeData_typemap[keyType];
			assert(desc and desc.write, "type declare invalid: name==>" .. v['k'])
			for i=1, #srcVal do
				assert(type(srcVal[i])~= 'nil', "declare field value empty: { " .. v['k'] .. '['..i..']=nil }')
				if v.s and v.s>0 then
					desc.write(obj, srcVal[i], v.s)
				else
					desc.write(obj, srcVal[i])
				end
			end
		end
		
		
	end
end

--
local function TypeData_read(declare, TypeData_typemap, obj)
	assert(declare and TypeData_typemap)
	assert(obj)
	local ret={}
	for k,v in pairs(declare) do
		assert(v and v['t'] and v['k']);
		local reader = function()
			if type(v.t) == 'table' or v['d'] then
				local sub = v.d or v.t
				assert(sub and #sub>0, 'type declare subtype empty name=>'..v['k'])
				return TypeData_read(sub, TypeData_typemap, obj)
			else
				local keyType = string.lower(v["t"]);		
				local desc = TypeData_typemap[keyType];
				assert(desc and desc.read, "type declare invalid: name==>" .. v['k'])
				return desc.read(obj, v.s)
			end
		end
		local LenArray = LenFieldFormat(v.l)
		if LenArray and #LenArray>0 then
			ret[v.k] = LenArrayRead(LenArray, reader)
		else
			ret[v.k] = reader()
		end
	end
	return ret
end
-----

-----

local function getTypeData_typemap()
	local int64 = Integer64.new();
	local CCmd_Data_readscore2 = function(buff)
		return buff:readscore(int64):getvalue()
	end
    local TypeData_typemap = {
		byte = {len=1, read=CCmd_Data.readbyte, write=CCmd_Data.pushbyte, },
		int = {len=4, read=CCmd_Data.readint, write=CCmd_Data.pushint, },
		word = {len=2, read=CCmd_Data.readword, write=CCmd_Data.pushword, },
		short = {len=2, read=CCmd_Data.readshort, write=CCmd_Data.pushshort, },
		dword = {len=4, read=CCmd_Data.readdword, write=CCmd_Data.pushdword, },
		bool = {len=1, read=CCmd_Data.readbool, write=CCmd_Data.pushbool, },
		double = {len=8, read=CCmd_Data.readdouble, write=CCmd_Data.pushdouble, },
		float = {len=4, read=CCmd_Data.readfloat, write=CCmd_Data.pushfloat, },

		string = {len=2, read=CCmd_Data.readstring, write=CCmd_Data.pushstring, },
		score = {len=8, read=CCmd_Data_readscore2, write=CCmd_Data.pushscore, },
    }
	TypeData_typemap['tchar'] = TypeData_typemap.string
	return TypeData_typemap
end

local function decode( declare, buff )
	local TypeData_typemap = getTypeData_typemap()
    local len1 = buff:getlen()
	local len2 = TypeData_getsize(declare, TypeData_typemap)
	assert( len1 == len2 )
	local ret = TypeData_read(declare, TypeData_typemap, buff)
	return ret
end

local function encode( declare, cmd1, cmd2, srcData )
	local TypeData_typemap = getTypeData_typemap()
	local buff = CCmd_Data:create(0); -- =0会自动扩容
    if srcData then
	    buff:setcmdinfo(cmd1, cmd2)
    else
        srcData = cmd1
    end
	TypeData_write(declare, TypeData_typemap, srcData, buff)
    local len1 = buff:getcurlen()
	assert( len1 == TypeData_getsize(declare, TypeData_typemap) )
	return buff
end


--local MOCK_TEST = true
if MOCK_TEST then
	
	CCmd_Data={

	};
	Integer64={new=function()end}
	setmetatable(CCmd_Data, {
		__index=function(obj, k)
			if k:find('create') then
				return function() return {} end
			elseif k:find('read') then
				return function(obj) 
					local r = obj[1];
					table.remove(obj, 1)
					return r
				end
			elseif k:find('push') then
				return function(obj, val, u) 
					table.insert(obj, val);
					--print('push', val, u) 
				end
			else 
				error('unk method')
			end
		end
	})
	
		
	local cmd={}
	cmd.CMD_S_ITEM = {
		{k='item', t='byte', l=4}
	}
	cmd.CMD_C_OperateCard = 
	{
		{k = "cbOperateCode", t = "byte"},							--操作代码
		{k = "cbOperateCard", t = "byte", l = {3}},					--操作扑克
		{k='name', t='string', s=4 },
		{k='userlist', t='byte', l={2,4,2} },
		{k='itemlist', t='table', d=cmd.CMD_S_ITEM },
		{k='itemlist2', t='table', d=cmd.CMD_S_ITEM, l=2},
	}

	local r=
	encode(cmd.CMD_C_OperateCard, {
		cbOperateCode=1,
		cbOperateCard={2,3,4},
		name = "asdf",
		userlist={ {11,12,13,14}, {21,22,23,24} },
		userlist={ {{111,112},{121,122},{131,132},{141,142}}, {{211,212},{221,222},{231,232},{241,242}} },
		itemlist={item={41,42,43,44}},
		itemlist2={ {item={51,52,53,54}}, {item={61,62,63,64}} },
	})


	print( unpack(r) )
	print('-------')
	r = decode(cmd.CMD_C_OperateCard, r)
	--r = r.itemlist2[2].item
	for k,v in pairs(r)do
		print(k,v)
	end
	print('-------')
end

local function bytes_reserve(tbl, maxlen)
    local now = #tbl
    if now < maxlen then
        tbl = clone(tbl)
        for i=now+1, maxlen do
            table.insert(tbl, 0)
        end
    end
    return tbl
end

return {
	encode = encode,
	decode = decode,
    bytes_reserve = bytes_reserve,
}

