require("mod-gui")

NUM_LINES = 50
--[[ 
	
--]]

function printable(v)
	if v == nil then return "nil"
	elseif v == true then return "true" 
	elseif v == false then return "false"
	elseif type(v) == type({}) then return "<table>"
	else return v end
end

function init_command_list_ui()
	if global.command_list_ui then return end
	global.command_list_ui = {}
	global.command_list_ui.ui_hidden = {}
	
end

function create_command_list_ui(player)
	local flow = mod_gui.get_frame_flow(player)
	if not flow.direction == "vertical" then flow.direction = "vertical" end
	local frame = flow.command_list_frame
	if frame and frame.valid then frame.destroy() end
	frame = flow.add{type="frame", name="command_list_frame", style="frame_style", direction="vertical"}

	local top_flow = frame.add{type="flow", name="top_flow", style="flow_style", direction="horizontal"}
	local title = top_flow.add{type="label", style="label_style", name = "title", caption="Command List"}
	title.style.font = "default-frame"
	top_flow.add{type="label", style="label_style", name = "title_show", caption="                    [Show]"}
	top_flow.add{type="checkbox", name="show_checkbox", state=true}

	frame.add{type="label", style="label_style", name="current_command_group", caption = "Active Command Group"}
	frame.add{type="label", style="label_style", name="required_for_next", caption = "Required for next"}

	local scroll_pane = frame.add{type="scroll-pane", name="scroll_pane", style="scroll_pane_style", direction="vertical", caption="foo"}
	scroll_pane.style.maximal_height = 200
	scroll_pane.style.maximal_width = 500
	scroll_pane.style.minimal_height = 100
	scroll_pane.style.minimal_width = 50

	for index=1, NUM_LINES do
		local label = scroll_pane.add{type="label", style="label_style", name = "text_" .. index, caption="", single_line=true, want_ellipsis=true}
		label.style.top_padding = 0
		label.style.bottom_padding = 0
		--label.style.font_color = {r=1.0, g=0.7, b=0.9}

	end
end


function update_command_list_ui(player, command_list)
	local flow = mod_gui.get_frame_flow(player)
	local frame = flow.command_list_frame

	if global.command_list_ui then init_command_list_ui(); return end

	if not frame then 
		create_command_list_ui(player) 
		frame = flow.command_list_frame
	end

	-- Visibility
	local show = frame.top_flow.show_checkbox.state
	if global.log_data.ui_hidden[player.index] ~= not show then
		frame.scroll_pane.style.visible = show
		--frame.type_flow.style.visible = show
		global.log_data.ui_hidden[player.index] = not show
	end

	-- Scheduling
	if game.tick % math.floor(game.speed * 20 + 1) ~= 0 then return end
	if not command_list then return end


	-- Update
	if show and not global.log_data.ui_paused[player.index] then

		if not global.current_command_group_index or not command_list[global.current_command_group_index] then return end
		local current_command_group = command_list[global.current_command_group_index]
		frame.current_command_group.caption = current_command_group.name

		local next_command_group = command_list[global.current_command_group_index + 1]
		if next_command_group then
			if next_command_group.required then
				local s = ""
				for _, name in ipairs(next_command_group.required) do
					if not global.finished_command_names[name] then
						s = s .. name .. " | "
					end
				end
				frame.required_for_next.caption = "Required: | " .. s
			else
				frame.required_for_next.caption = "Required: <All>"
			end
		else
			frame.required_for_next.caption = "End of Input."
		end

		local command_set_index = 1
		for index = 1, NUM_LINES do
			local command = nil
			repeat
				command = global.current_command_set[command_set_index]
				command_set_index = command_set_index + 1
			until (command and not command.finished) or command_set_index > #global.current_command_set

			if command then 
				s = "[" .. index .. "] | "
				for key, value in pairs(command) do
					s = s .. key .. "= " .. printable(value) .. " | "
				end
				frame.scroll_pane["text_" .. index].caption = s
			else
				frame.scroll_pane["text_" .. index].caption = ""
			end
		end
	end
end

function destroy_command_list_ui(player)
	local fr = mod_gui.get_frame_flow(player).command_list_frame
	if fr and fr.valid then fr.destroy() end
end

