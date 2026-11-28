-- Test-only source-extracted DBM functions are supplied by the cloud runner.
-- Stock Lua cannot create WoW secret numbers; __lt traps the same operation.
function DBM_RANGE_CASES(makeFrame, attach, label)
    local count = 0
    local function scenario(icon, flags)
        local case = DBM_RANGE_FACTORY(icon, makeFrame, flags or {})
        if attach then attach(case.range) end
        -- A post-observer is deliberately reached only after native success.
        local native, postCalls = case.range.Show, 0
        case.range.Show = function(...)
            local result = table.pack(native(...))
            postCalls = postCalls + 1
            return table.unpack(result, 1, result.n)
        end
        return case, function() return postCalls end
    end
    for _, entry in ipairs({{nil}, {1}, {8}, {9}}) do
        local value = entry[1]
        local case, post = scenario(value)
        assert(pcall(case.click), 'public icon failed: ' .. label)
        local expected = value and value < 9 and value or nil
        assert(case.icons[1] == expected and case.state.reads == 1)
        assert(post() == 1 and case.state.played, 'native success did not complete')
        count = count + 1
    end
    local opaque = setmetatable({}, {__lt = function()
        error('SIMULATED secret-number comparison: icon < 9', 0)
    end})
    for _, raid in ipairs({false, true}) do
        local case, post = scenario(opaque, {raid = raid})
        local ok, err = pcall(case.click)
        assert(not ok and tostring(err):find('SIMULATED secret-number comparison: icon < 9', 1, true),
            'native comparison was not reproduced: ' .. label)
        assert(case.state.reads == 1 and post() == 0 and not case.state.played,
            'skin post-hook ran after failed native Show')
        assert(case.state.unit == (raid and 'raid1' or 'party1'))
        count = count + 1
    end
    -- DBM's existing restrictions/combat check prevents the API call here,
    -- but it does not protect the noncombat case above.
    local case, post = scenario(opaque, {combat = true, restricted = true})
    assert(pcall(case.click) and case.state.reads == 0 and post() == 1)
    count = count + 1
    print('PASS: native RangeCheck source ' .. label .. ' cases=' .. count ..
        '; secret comparison precedes Show post-hook')
end
