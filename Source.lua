-- ===================================================================
-- SourceOS v1.0.0 "Release" (Secure Shell with JSON DB & Sudo)
-- Powered by CraftOS Kernel & BIOS
-- Path: /Source.lua
-- Database: /users.json
-- Plugins: /plugins_source/
-- Developer: Mifichenskiy
-- ===================================================================

local running = false
local current_user = ""
local logged_in_user = "" -- Реально залогиненный юзер; НЕ меняется при sudo (в отличие от current_user)
local hostname = "SourcePC"
local plugin_dir = "/plugins_source/"
local db_path = "/users.json"
local shop_db_path = "/shop_inventory.json"
local sales_log_path = "/sales_log.json"
local pms_manifest_url = "https://raw.githubusercontent.com/Mifichenskiy/SourceOS-Packages/main/packages.json"

local users = {}
local shop = {}
local sales_log = {}

-- Функции для работы с JSON базой данных
local function load_db()
    if fs.exists(db_path) then
        local file = fs.open(db_path, "r")
        local content = file.readAll()
        file.close()
        users = textutils.unserializeJSON(content) or {}
    else
        -- Дефолтная база, если файла нет
        users = {
            ["root"] = { pass = "dev//00**jj", wheel = true },
            ["toha"] = { pass = "t2x2_stream", wheel = true }
        }
        local file = fs.open(db_path, "w")
        file.write(textutils.serializeJSON(users))
        file.close()
    end
end

local function save_db()
    local file = fs.open(db_path, "w")
    file.write(textutils.serializeJSON(users))
    file.close()
end

-- Функции для работы с базой товаров магазина
local function load_shop_db()
    if fs.exists(shop_db_path) then
        local file = fs.open(shop_db_path, "r")
        local content = file.readAll()
        file.close()
        shop = textutils.unserializeJSON(content) or {}
    else
        shop = {} -- Пустой каталог по умолчанию, добавляется через additem
        local file = fs.open(shop_db_path, "w")
        file.write(textutils.serializeJSON(shop))
        file.close()
    end
end

local function save_shop_db()
    local file = fs.open(shop_db_path, "w")
    file.write(textutils.serializeJSON(shop))
    file.close()
end

-- Функции для работы с логом продаж
local function load_sales_log()
    if fs.exists(sales_log_path) then
        local file = fs.open(sales_log_path, "r")
        local content = file.readAll()
        file.close()
        sales_log = textutils.unserializeJSON(content) or {}
    else
        sales_log = {}
        local file = fs.open(sales_log_path, "w")
        file.write(textutils.serializeJSON(sales_log))
        file.close()
    end
end

local function save_sales_log()
    local file = fs.open(sales_log_path, "w")
    file.write(textutils.serializeJSON(sales_log))
    file.close()
end

local function linux_clear()
    term.clear()
    term.setCursorPos(1, 1)
end

-- Инициализация системы
load_db()
load_shop_db()
load_sales_log()
linux_clear()
if term.isColor() then term.setTextColor(colors.orange) end
print("[SourceOS] Initializing monolithic kernel from /Source.lua...")
sleep(0.2)
print("[SourceOS] Synced readable database via " .. db_path .. "... OK")
sleep(0.2)

-- Бесконечный цикл авторизации
while not running do
    print("\n---------------------------------------------------")
    if term.isColor() then term.setTextColor(colors.cyan) end
    print("=== SourceOS Access Control System ===")
    if term.isColor() then term.setTextColor(colors.white) end

    write("Login: ")
    local input_user = read()

    write("Password: ")
    local input_pass = read("*")

    print("---------------------------------------------------")
    print("Authenticating...")
    sleep(0.4)

    if users[input_user] and users[input_user].pass == input_pass then
        current_user = input_user
        logged_in_user = input_user
        running = true
        if term.isColor() then term.setTextColor(colors.green) end
        print("ACCESS GRANTED. Welcome back, " .. current_user .. "!")
        sleep(0.5)
    else
        if term.isColor() then term.setTextColor(colors.red) end
        print("ACCESS DENIED. Invalid username or password.")
        print("Please try again.")
        if term.isColor() then term.setTextColor(colors.white) end
        sleep(1.2)
    end
end

-- Обработчик одной команды. Используется и главным циклом, и sudo (вместо shell.run,
-- который не знает о внутренних командах SourceOS и ищет их как файлы-программы).
local function execute_command(input)
    local args = {}
    for word in input:gmatch("%S+") do table.insert(args, word) end

    local cmd = args[1] and string.lower(args[1]) or nil

    if cmd then
        -- 1. CLEAR Command
        if cmd == "clear" then

            linux_clear()

        -- 2. VIM / NVIM Command (Staff only — can edit any file including users.json)
        elseif cmd == "vim" or cmd == "nvim" then
            if not users[current_user].wheel then
                print(cmd .. ": Permission denied (staff privileges required)")
            else
                local file_to_edit = args[2] -- Вернул ваш индекс!
                if file_to_edit then shell.run("/rom/programs/edit.lua", file_to_edit)
                else print("Error: Specify file name. Example: vim script.lua") end
            end

        -- 3. CMADD Command (Staff only — Теперь строго со строковыми переменными)
        elseif cmd == "cmadd" then
            if not users[current_user].wheel then
                print("cmadd: Permission denied (staff privileges required)")
            else
            local reserved = {
                clear=true, vim=true, nvim=true, cmadd=true, sfac=true, ls=true,
                cat=true, useradd=true, passwd=true, wheel=true, sudo=true,
                redstone=true, rs=true, sourcefetch=true, help=true, exit=true,
                pms=true, stock=true, sell=true, additem=true, setprice=true,
                restock=true, sales=true, git=true
            }

            write("Enter new command name: ")
            local name = read()
            
            if name == "" then
                print("Error: Command name cannot be empty!")
            elseif reserved[string.lower(name)] then
                print("Error: '" .. name .. "' is a reserved built-in command and will never be reachable.")
            else
                name = name:gsub("[/%.\\]", "") -- Защита от выхода из папки
                
                -- Убираем лишние слэши для стабильности ФС CraftOS
                local clean_dir = plugin_dir:gsub("^/", "")
                local path = clean_dir .. name .. ".lua"
                
                if not fs.exists(clean_dir) then
                    fs.makeDir(clean_dir)
                end

                if fs.exists(path) then
                    write("Plugin '" .. name .. "' already exists. Overwrite? (y/n): ")
                    local confirm = read()
                    if string.lower(confirm) ~= "y" then
                        print("Cancelled.")
                        goto cmadd_done
                    end
                end
                
                print("Enter your Lua code (type '.end' on its own line to finish, empty lines allowed):")
                local lines = {}
                while true do
                    local line = read()
                    if line == ".end" then break end
                    table.insert(lines, line)
                end
                
                if #lines == 0 then
                    table.insert(lines, "print('Custom command " .. name .. " works!')")
                end
                
                local file = fs.open(path, "w")
                if file then
                    file.write(table.concat(lines, "\n"))
                    file.close()
                    print("Command '" .. name .. "' successfully added to " .. plugin_dir)
                else
                    print("Error: Could not open file for writing at: " .. path)
                end
                ::cmadd_done::
            end
            end

        -- 4. SFAC Command
        elseif cmd == "sfac" or cmd == "SFAC" then
            print("\n[SFAC Engine Activated]")
            print("Struktura: Clean root tree. Independent monolithic design.")
            print("Files: Dynamic JSON database mapped to " .. db_path)
            print("And Code: Admin tools (useradd, passwd, wheel, sudo) integrated.\n")

        -- 5. LS Command
        elseif cmd == "ls" then
            shell.run("/rom/programs/list.lua")
            if fs.exists(plugin_dir) then
                if term.isColor() then term.setTextColor(colors.orange) end
                print("\nAvailable plugins:")
                if term.isColor() then term.setTextColor(colors.white) end
                shell.run("/rom/programs/list.lua", plugin_dir)
            end

        -- 6. CAT Command
        elseif cmd == "cat" then
            local file_to_read = args[2] -- Вернул ваш индекс!
            if file_to_read then
                -- Защита базы паролей от чтения не-root пользователями
                local normalized = "/" .. file_to_read:gsub("^/", "")
                if normalized == db_path and current_user ~= "root" then
                    print("cat: Permission denied: " .. file_to_read)
                else
                    shell.run("/rom/programs/type.lua", file_to_read)
                end
            else print("Usage: cat [filename]") end
        -- 7. USERADD Command (Only for root)
        elseif cmd == "useradd" then
            if current_user ~= "root" then
                print("useradd: Permission denied (root privileges required)")
            else
                local new_user = args[2]
                if new_user then
                    if users[new_user] then
                        print("useradd: User '" .. new_user .. "' already exists.")
                    else
                        users[new_user] = { pass = "password", wheel = false }
                        save_db()
                        print("User '" .. new_user .. "' created with default password 'password'.")
                    end
                else
                    print("Usage: useradd [username]")
                end
            end

        -- 8. PASSWD Command (Only for root)
        elseif cmd == "passwd" then
            if current_user ~= "root" then
                print("passwd: Permission denied (root privileges required)")
            else
                local target_user = args[2]
                if target_user and users[target_user] then
                    write("Enter new password for " .. target_user .. ": ")
                    local new_pass = read("*")
                    users[target_user].pass = new_pass
                    save_db()
                    print("Password updated successfully.")
                else
                    print("Usage: passwd [username]")
                end
            end

        -- 9. WHEEL Command (Only for root)
        elseif cmd == "wheel" then
            if current_user ~= "root" then
                print("wheel: Permission denied (root privileges required)")
            else
                local target_user = args[2]
                local action = args[3]
                if target_user and action and users[target_user] then
                    if action == "add" then
                        users[target_user].wheel = true
                        save_db()
                        print("User '" .. target_user .. "' added to wheel group.")
                    elseif action == "remove" then
                        if target_user == "root" then
                            print("Error: Cannot remove root from wheel group.")
                        else
                            users[target_user].wheel = false
                            save_db()
                            print("User '" .. target_user .. "' removed from wheel group.")
                        end
                    else
                        print("Invalid action. Use 'add' or 'remove'.")
                    end
                else
                    print("Usage: wheel [username] [add/remove]")
                end
            end

        -- 10. SUDO Command (Requires wheel group privileges)
        elseif cmd == "sudo" then
            if not users[current_user].wheel then
                print(current_user .. " is not in the sudoers file. This incident will be reported.")
            else
                write("[sudo] password for " .. current_user .. ": ")
                local sudo_pass = read("*")
                if users[current_user].pass == sudo_pass then
                    local sudo_cmd_string = ""
                    for i = 2, #args do sudo_cmd_string = sudo_cmd_string .. args[i] .. " " end
                    sudo_cmd_string = sudo_cmd_string:gsub("%s+$", "") -- убираем хвостовой пробел

                    if sudo_cmd_string == "" then
                        print("Usage: sudo [command]")
                    else
                        local backup_user = current_user
                        current_user = "root"
                        print("[sudo] Executing command with root privileges...")
                        local ok, err = pcall(execute_command, sudo_cmd_string)
                        current_user = backup_user
                        if not ok then
                            if term.isColor() then term.setTextColor(colors.red) end
                            print("sudo: command failed: " .. tostring(err))
                            if term.isColor() then term.setTextColor(colors.white) end
                        end
                    end
                else
                    print("Sorry, try again.")
                end
            end

        -- 11. REDSTONE / RS Command (Admin/staff only — controls command block triggers)
        elseif cmd == "redstone" or cmd == "rs" then
            if not users[current_user].wheel then
                print("redstone: Permission denied (staff privileges required)")
            else
            local side = args[2]
            local state = args[3]
            local requested_time = args[4] and tonumber(args[4]) or nil

            if side and state then
                local valid_sides = { back=true, front=true, top=true, bottom=true, left=true, right=true }
                if valid_sides[side] then
                    if state == "on" then
                        -- Лимиты длительности по правам доступа
                        -- ВАЖНО: используем logged_in_user (реальный юзер), а не current_user,
                        -- иначе wheel-юзер через "sudo rs ..." получает current_user == "root"
                        -- и обходит свой 7-секундный лимит, получая бесконечный сигнал как root.
                        local is_root = (logged_in_user == "root")
                        local is_wheel = users[current_user].wheel
                        local max_time -- nil = без ограничений
                        local default_time -- время по умолчанию, если пользователь не указал своё

                        if is_root then
                            max_time = nil
                            default_time = nil -- root: висит вечно, пока не off
                        elseif is_wheel then
                            max_time = 7
                            default_time = 7
                        else
                            max_time = 3
                            default_time = 3
                        end

                        local actual_time = requested_time or default_time
                        if actual_time and args[4] and not requested_time then
                            print("Error: Invalid time value '" .. args[4] .. "'.")
                        else
                            if actual_time and max_time and actual_time > max_time then
                                print("[SourceOS] Time capped at " .. max_time .. "s for your permission level.")
                                actual_time = max_time
                            end

                            redstone.setOutput(side, true)
                            if actual_time then
                                print("[SourceOS] Redstone on '" .. side .. "' set to ON for " .. actual_time .. "s.")
                                sleep(actual_time)
                                redstone.setOutput(side, false)
                                print("[SourceOS] Redstone on '" .. side .. "' auto-OFF after " .. actual_time .. "s.")
                            else
                                print("[SourceOS] Redstone on '" .. side .. "' set to ON (root: no auto-off).")
                            end
                        end
                    elseif state == "off" then 
                        redstone.setOutput(side, false)
                        print("[SourceOS] Redstone on '" .. side .. "' set to OFF.")
                    else print("Error: Use 'on' or 'off'") end
                else print("Error: Invalid side name.") end
            else print("Usage: redstone [side] [on/off] [time_in_seconds]") end
            end

        -- 12. SOURCEFETCH Command
        elseif cmd == "sourcefetch" then
            local logo = { "   ____ ___  ", "  / ___/ ___|", "  \\___ \\___ \\", "  ____) ___) |", " |____/____/ ", "  SourceOS   " }
            local free_space = math.floor(fs.getFreeSpace("/") / 1024 / 1024) .. " MB"
            local game_time = textutils.formatTime(os.time(), true)
            print("")
            for i = 1, math.max(#logo, 6) do
                if term.isColor() then term.setTextColor(colors.orange) write((logo[i] or "             ") .. "   ") end
                term.setTextColor(colors.white)
                if i == 1 then print(current_user .. "@" .. hostname)
                elseif i == 2 then print("------------------")
                elseif i == 3 then print("OS: SourceOS v1.0.0")
                elseif i == 4 then print("User Mode: " .. (users[current_user].wheel and "Wheel/Admin" or "Standard"))
                elseif i == 5 then print("Uptime: " .. game_time)
                elseif i == 6 then print("Disk Left: " .. free_space) end
            end
            print("")

        -- 13. HELP Command (filtered by role — cashiers don't see staff/admin commands)
        elseif cmd == "help" then
            local is_wheel = users[current_user].wheel
            local is_root = (current_user == "root")

            print("Available commands:")
            print("  clear       - Clear screen")
            print("  ls / cat    - File and plugin management")
            print("  sourcefetch - Show system statistics")
            print("  exit        - Log out and return to CraftOS")

            if is_wheel then
                print("\n-- Staff commands --")
                print("  vim [file]  - Edit/create file via Vim")
                print("  cmadd       - Add custom command")
                print("  redstone    - Control redstone pins (rs) [side] [on/off] [time]")
                print("  sudo [cmd]  - Run command as root (wheel group only)")
            end

            if is_root then
                print("\n-- Root commands --")
                print("  useradd/passwd/wheel - Account management")
                print("  pms [list/install/remove/installed] - Package manager")
                print("  git [clone/pull] owner/repo - Pull files from GitHub")
            end

        -- 16. STOCK Command (everyone — view catalog and prices)
        elseif cmd == "stock" then
            local any = false
            if term.isColor() then term.setTextColor(colors.cyan) end
            print(string.format("%-16s %-10s %-8s", "ITEM", "PRICE", "QTY"))
            if term.isColor() then term.setTextColor(colors.white) end
            for name, info in pairs(shop) do
                any = true
                print(string.format("%-16s %-10s %-8s", name, info.price, info.qty))
            end
            if not any then print("Shop catalog is empty. Use 'additem' to add products.") end

        -- 17. ADDITEM Command (Staff only — add a new product to the catalog)
        elseif cmd == "additem" then
            if not users[current_user].wheel then
                print("additem: Permission denied (staff privileges required)")
            else
                local item_name = args[2]
                local price = tonumber(args[3])
                local qty = tonumber(args[4]) or 0
                if not item_name or not price then
                    print("Usage: additem [name] [price] [starting_qty]")
                elseif shop[item_name] then
                    print("additem: Item '" .. item_name .. "' already exists. Use 'restock' or 'setprice'.")
                else
                    shop[item_name] = { price = price, qty = qty }
                    save_shop_db()
                    print("Item '" .. item_name .. "' added: price " .. price .. ", qty " .. qty .. ".")
                end
            end

        -- 18. SETPRICE Command (Staff only)
        elseif cmd == "setprice" then
            if not users[current_user].wheel then
                print("setprice: Permission denied (staff privileges required)")
            else
                local item_name = args[2]
                local price = tonumber(args[3])
                if not item_name or not price then
                    print("Usage: setprice [name] [new_price]")
                elseif not shop[item_name] then
                    print("setprice: Item '" .. item_name .. "' not found.")
                else
                    shop[item_name].price = price
                    save_shop_db()
                    print("Price for '" .. item_name .. "' updated to " .. price .. ".")
                end
            end

        -- 19. RESTOCK Command (Staff only — add quantity to existing item)
        elseif cmd == "restock" then
            if not users[current_user].wheel then
                print("restock: Permission denied (staff privileges required)")
            else
                local item_name = args[2]
                local qty = tonumber(args[3])
                if not item_name or not qty then
                    print("Usage: restock [name] [qty]")
                elseif not shop[item_name] then
                    print("restock: Item '" .. item_name .. "' not found. Use 'additem' first.")
                else
                    shop[item_name].qty = shop[item_name].qty + qty
                    save_shop_db()
                    print("'" .. item_name .. "' restocked. New qty: " .. shop[item_name].qty)
                end
            end

        -- 20. SELL Command (everyone — the core cashier command)
        elseif cmd == "sell" then
            local item_name = args[2]
            local qty = tonumber(args[3]) or 1
            if not item_name then
                print("Usage: sell [item] [qty]")
            elseif not shop[item_name] then
                print("sell: Item '" .. item_name .. "' not found. Check 'stock' for available items.")
            elseif qty <= 0 then
                print("sell: Quantity must be greater than 0.")
            elseif shop[item_name].qty < qty then
                print("sell: Not enough stock. Available: " .. shop[item_name].qty)
            else
                local total = shop[item_name].price * qty
                shop[item_name].qty = shop[item_name].qty - qty
                save_shop_db()

                table.insert(sales_log, {
                    cashier = current_user,
                    item = item_name,
                    qty = qty,
                    total = total,
                    time = textutils.formatTime(os.time(), true) .. " (day " .. os.day() .. ")"
                })
                save_sales_log()

                if term.isColor() then term.setTextColor(colors.green) end
                print("---------------------------------------------------")
                print("SALE COMPLETE")
                print("Item: " .. item_name .. " x" .. qty)
                print("Total: " .. total)
                print("Cashier: " .. current_user)
                print("---------------------------------------------------")
                if term.isColor() then term.setTextColor(colors.white) end
            end

        -- 21. SALES Command (Staff only — view sales log)
        elseif cmd == "sales" then
            if not users[current_user].wheel then
                print("sales: Permission denied (staff privileges required)")
            else
                if #sales_log == 0 then
                    print("No sales recorded yet.")
                else
                    local grand_total = 0
                    for i, entry in ipairs(sales_log) do
                        print(entry.time .. " | " .. entry.cashier .. " sold " .. entry.qty .. "x " .. entry.item .. " for " .. entry.total)
                        grand_total = grand_total + entry.total
                    end
                    print("---------------------------------------------------")
                    print("Grand total: " .. grand_total)
                end
            end

        -- 22. PMS Command (Package Manager Source — root only, sudo also works)
        elseif cmd == "pms" then
            if current_user ~= "root" then
                print("pms: Permission denied (root privileges required). Try 'sudo pms ...'.")
            elseif not http then
                print("pms: HTTP API is disabled on this server. Ask the admin to enable it.")
            else
                local sub = args[2]

                local function fetch_manifest()
                    local response = http.get(pms_manifest_url)
                    if not response then
                        print("pms: Could not reach manifest at " .. pms_manifest_url)
                        return nil
                    end
                    local body = response.readAll()
                    response.close()
                    local ok, data = pcall(textutils.unserializeJSON, body)
                    if not ok or not data then
                        print("pms: Manifest is not valid JSON.")
                        return nil
                    end
                    return data
                end

                if sub == "list" then
                    local packages = fetch_manifest()
                    if packages then
                        print("Available packages:")
                        for name, info in pairs(packages) do
                            print("  " .. name .. (info.description and (" - " .. info.description) or ""))
                        end
                    end

                elseif sub == "install" then
                    local pkg_name = args[3]
                    if not pkg_name then
                        print("Usage: pms install [package]")
                    else
                        local packages = fetch_manifest()
                        if packages then
                            local pkg = packages[pkg_name]
                            if not pkg or not pkg.url then
                                print("pms: Package '" .. pkg_name .. "' not found in manifest.")
                            else
                                local response = http.get(pkg.url)
                                if not response then
                                    print("pms: Failed to download '" .. pkg_name .. "' from " .. pkg.url)
                                else
                                    local content = response.readAll()
                                    response.close()

                                    local clean_dir = plugin_dir:gsub("^/", "")
                                    if not fs.exists(clean_dir) then fs.makeDir(clean_dir) end

                                    local path = clean_dir .. pkg_name .. ".lua"
                                    local file = fs.open(path, "w")
                                    file.write(content)
                                    file.close()
                                    print("pms: Installed '" .. pkg_name .. "' to " .. plugin_dir)
                                end
                            end
                        end
                    end

                elseif sub == "remove" then
                    local pkg_name = args[3]
                    if not pkg_name then
                        print("Usage: pms remove [package]")
                    else
                        local clean_dir = plugin_dir:gsub("^/", "")
                        local path = clean_dir .. pkg_name .. ".lua"
                        if fs.exists(path) then
                            fs.delete(path)
                            print("pms: Removed '" .. pkg_name .. "'.")
                        else
                            print("pms: Package '" .. pkg_name .. "' is not installed.")
                        end
                    end

                elseif sub == "installed" then
                    local clean_dir = plugin_dir:gsub("^/", "")
                    if fs.exists(clean_dir) then
                        local files = fs.list(clean_dir)
                        if #files == 0 then
                            print("No packages installed.")
                        else
                            print("Installed packages:")
                            for _, f in ipairs(files) do print("  " .. f:gsub("%.lua$", "")) end
                        end
                    else
                        print("No packages installed.")
                    end

                else
                    print("Usage: pms [list|install|remove|installed] [package]")
                end
            end

        -- 23. GIT Command (root only — recursively pull files from a public GitHub repo via API)
        elseif cmd == "git" then
            if current_user ~= "root" then
                print("git: Permission denied (root privileges required). Try 'sudo git ...'.")
            elseif not http then
                print("git: HTTP API is disabled on this server. Ask the admin to enable it.")
            else
                local sub = args[2]

                if sub == "clone" or sub == "pull" then
                    local repo_arg = args[3] -- ожидаем формат owner/repo
                    local remote_path = args[4] or "" -- путь внутри репо, по умолчанию корень
                    local local_dir = args[5]

                    if not repo_arg or not repo_arg:find("/") then
                        print("Usage: git " .. sub .. " owner/repo [path_in_repo] [local_dir]")
                    else
                        local owner, repo = repo_arg:match("^([^/]+)/([^/]+)$")
                        if not owner or not repo then
                            print("git: Invalid repo format. Use owner/repo.")
                        else
                            local_dir = local_dir or ("/" .. repo .. "/")
                            if not local_dir:match("/$") then local_dir = local_dir .. "/" end

                            local file_count = 0
                            local headers = { ["User-Agent"] = "SourceOS-git" }

                            -- Рекурсивно обходит дерево каталогов через GitHub Contents API
                            local function fetch_dir(api_path, disk_path)
                                local api_url = "https://api.github.com/repos/" .. owner .. "/" .. repo .. "/contents/" .. api_path
                                local response = http.get(api_url, headers)
                                if not response then
                                    print("git: Failed to reach " .. api_url)
                                    return false
                                end
                                local body = response.readAll()
                                response.close()

                                local ok, items = pcall(textutils.unserializeJSON, body)
                                if not ok or not items then
                                    print("git: Bad response for path '" .. api_path .. "' (repo/path may not exist, or rate-limited).")
                                    return false
                                end

                                if not fs.exists(disk_path) then fs.makeDir(disk_path) end

                                for _, item in ipairs(items) do
                                    if item.type == "dir" then
                                        fetch_dir(item.path, disk_path .. item.name .. "/")
                                    elseif item.type == "file" and item.download_url then
                                        local file_resp = http.get(item.download_url, headers)
                                        if file_resp then
                                            local content = file_resp.readAll()
                                            file_resp.close()
                                            local f = fs.open(disk_path .. item.name, "w")
                                            f.write(content)
                                            f.close()
                                            file_count = file_count + 1
                                            print("  + " .. disk_path .. item.name)
                                        else
                                            print("  ! failed: " .. item.name)
                                        end
                                    end
                                end
                                return true
                            end

                            print("[git] Fetching " .. owner .. "/" .. repo .. (remote_path ~= "" and (":" .. remote_path) or "") .. " ...")
                            local ok = fetch_dir(remote_path, local_dir)
                            if ok then
                                print("[git] Done. " .. file_count .. " file(s) written to " .. local_dir)
                            end
                        end
                    end

                else
                    print("Usage: git [clone|pull] owner/repo [path_in_repo] [local_dir]")
                end
            end

        -- 14. EXIT Command
        elseif cmd == "exit" then
            print("[SourceOS] Logging out from session...")
            sleep(0.3)
            running = false

        -- 15. Fallback to plugins folder or system rom
        else
            local clean_dir = plugin_dir:gsub("^/", "")
            local plugin_path = clean_dir .. cmd .. ".lua"
            
            if fs.exists(plugin_path) then
                local sub_args = {}
                for k, v in ipairs(args) do if k > 1 then table.insert(sub_args, v) end end
                shell.run(plugin_path, table.unpack(sub_args))
            else
                local success = shell.run(input)
                if not success then
                    if term.isColor() then term.setTextColor(colors.red) end
                    print("bash: " .. cmd .. ": command not found")
                    if term.isColor() then term.setTextColor(colors.white) end
                end
            end
        end
    end
end

-- Вход в шелл после успешной авторизации
linux_clear()
if term.isColor() then term.setTextColor(colors.white) end
print("Welcome to SourceOS!")
print("Type 'help' to see available commands. Type 'exit' to log out.")
print("---------------------------------------------------")
-- Главный цикл обработки команд (Event Loop)
while running do
    -- Отрисовка Linux-промпта (# для рута, $ для обычных пользователей)
    if term.isColor() then 
        term.setTextColor(colors.green)
        write(current_user .. "@" .. hostname)
        term.setTextColor(colors.white)
        write(":")
        term.setTextColor(colors.blue)
        write("~")
        term.setTextColor(colors.white)
        write(current_user == "root" and "# " or "$ ")
    else
        write(current_user .. "@" .. hostname .. ":~" .. (current_user == "root" and "# " or "$ "))
    end

    local input = read()
    if input == "" then input = " " end -- Защита от пустого ввода

    execute_command(input)
end
