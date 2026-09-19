-- Run after deployment: lua tests/verify-bracket-paging.lua <Rime user directory>
local root = assert(arg[1], 'Provide the Rime user directory')
local file = assert(io.open(root .. '/build/double_pinyin_flypy.schema.yaml', 'r'))
local schema = file:read('*a')
file:close()
local processor = dofile(root .. '/lua/select_character.lua')

-- Lua 5.1 fallback for this ASCII-only candidate fixture.
utf8 = utf8 or {offset = function(s, n) return n > 0 and n or #s + n + 1 end}
local committed = false
local context = {
    input = 'candidate', caret_pos = 9,
    is_composing = function() return true end,
    has_menu = function() return true end,
    get_selected_candidate = function() return {text = 'candidate'} end,
    get_commit_text = function() return 'candidate' end,
    clear = function() end,
    push_input = function() end,
}
local env = {engine = {
    context = context,
    commit_text = function() committed = true end,
    schema = {config = {get_string = function(_, path)
        local name = path:match('/([^/]+)$')
        local value = schema:match('\n  ' .. name .. ': ([^\r\n]+)')
        return value and value:gsub('^"(.*)"$', '%1')
    end}},
}}
processor.init(env)
local failed = false
for _, name in ipairs({'bracketleft', 'bracketright'}) do
    committed = false
    local result = processor.func({release = function() return false end,
        repr = function() return name end}, env)
    local passed = result == 2 and not committed
    print((passed and 'PASS: ' or 'FAIL: ') .. name .. ' reaches the paging key binder')
    failed = failed or not passed
end
assert(schema:find('{accept: bracketleft, send: Page_Up, when: paging}', 1, true), 'Missing previous-page binding')
assert(schema:find('{accept: bracketright, send: Page_Down, when: has_menu}', 1, true), 'Missing next-page binding')
os.exit(failed and 1 or 0)
