-- Aegisub Automation Script
-- This script adjusts the \1a value progressively for selected lines

script_name = "Gradual Transparency"
script_description = "Adjusts 1a value to make selected lines progressively more transparent"
script_author = "Akayuki"
script_version = "1.1"

include("karaskel.lua")

function adjust_transparency(subtitles, selected_lines, active_line)
    local dialog_config = {
        {class="label", label="Starting Alpha (Hex, 00-FF)", x=0, y=0, hint="00 = Fully opaque, FF = Fully transparent"},
        {class="edit", name="start_alpha", value="00", x=1, y=0},
        {class="label", label="Ending Alpha (Hex, 00-FF)", x=0, y=1, hint="00 = Fully opaque, FF = Fully transparent"},
        {class="edit", name="end_alpha", value="FF", x=1, y=1},
        {class="label", label="Use Custom Number of Steps?", x=0, y=2, hint="Check to use a custom number of steps"},
        {class="checkbox", name="use_custom_steps", value=false, x=1, y=2},
        {class="label", label="Number of Steps", x=0, y=3, hint="Positive integer value, default is the number of selected lines"},
        {class="intedit", name="steps", value=100, x=1, y=3, hint="Enter a positive integer, default is the number of selected lines"}
    }

    local buttons = {"OK", "Cancel"}
    local pressed, result = aegisub.dialog.display(dialog_config, buttons)

    if pressed ~= "OK" then
        aegisub.cancel()
    end

    local start_alpha = tonumber(result.start_alpha, 16)
    local end_alpha = tonumber(result.end_alpha, 16)
    local steps = #selected_lines  -- Default to number of selected lines if custom steps not used

    if result.use_custom_steps then
        steps = tonumber(result.steps)
    end

    if start_alpha == nil or end_alpha == nil or start_alpha < 0 or start_alpha > 255 or end_alpha < 0 or end_alpha > 255 or steps <= 0 then
        aegisub.dialog.display({{class="label", label="Invalid input. Please enter valid hex values for alpha (00-FF) and a positive number for steps.", x=0, y=0}}, {"OK"})
        aegisub.cancel()
    end

    local alpha_step = (end_alpha - start_alpha) / (steps - 1)

    for i, line_index in ipairs(selected_lines) do
        local line = subtitles[line_index]
        local new_alpha = math.floor(start_alpha + alpha_step * (i - 1))

        if new_alpha > end_alpha then
            new_alpha = end_alpha
        elseif new_alpha < start_alpha then
            new_alpha = start_alpha
        end

        -- Format the new_alpha to be a two-digit hexadecimal value
        new_alpha = string.format("%02X", new_alpha)

        -- Remove existing \1a tags and add the new one
        line.text = line.text:gsub("\\1a&H%x%x&", "")
        line.text = string.format("{\\1a&H%s&}%s", new_alpha, line.text)

        subtitles[line_index] = line
    end

    aegisub.set_undo_point(script_name)
end

aegisub.register_macro(script_name, script_description, adjust_transparency)
