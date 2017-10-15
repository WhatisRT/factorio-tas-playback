local mod_gui = require("mod-gui")

local Utils = require("utility_functions")
local NUM_LINES = 40

CmdUI = {} --luacheck: allow defined top

local passive_commands = {
	"passive-take",
	"auto-refuel",
	"pickup",
}


function CmdUI.init()
	if global.command_list_ui then return end
	global.command_list_ui = {}
	global.command_list_ui.ui_hidden = {}

end

function CmdUI.create(player)
	local flow = mod_gui.get_frame_flow(player)
	if not flow.direction == "vertical" then flow.direction = "vertical" end
	local frame = flow.command_list_frame
	if frame and frame.valid then frame.destroy() end
	frame = flow.add{type="frame", name="command_list_frame", style="frame_style", direction="vertical"}

	local top_flow = frame.add{type="flow", name="top_flow", style="flow_style", direction="horizontal"}
	local title = top_flow.add{type="label", style="label_style", name = "title", caption="Command List"}
	title.style.font = "default-frame"

	local label = top_flow.add{type="label", style="label_style", name = "title_show", caption="[Show]"}
	label.style.left_padding = 40
	local box = top_flow.add{type="checkbox", style="checkbox_style", name="show_command_list_ui_checkbox", state=true}
	box.style.top_padding = 3
	box.style.right_padding = 8

	top_flow.add{type="label", style="label_style", name = "title_show_passive", caption="[Show Passive]"}
	box = top_flow.add{type="checkbox", style="checkbox_style", name="show_passive_button", state=false}
	box.style.top_padding = 3
	box.style.right_padding = 8

	top_flow.add{type="label", style="label_style", name = "title_show_spawned", caption="[Show Spawned]"}
	box = top_flow.add{type="checkbox", style="checkbox_style", name="show_spawned_button", state=true}
	box.style.top_padding = 3
	box.style.right_padding = 8

	local group_flow = frame.add{type="flow", name="group_flow", style="flow_style", direction="horizontal"}
	local label = group_flow.add{type="label", style="label_style", name="current_command_group", caption = "Active Command Group"}
	label.style.font = "default-semibold"
	local button = group_flow.add{type="button", style="button_style", name="next_command_group", caption="Next Command Group"}
	button.style.top_padding = 0
	button.style.bottom_padding = 0
	button.style.font = "default-semibold"

	label = frame.add{type="label", style="label_style", name="required_for_next", caption = "Required for next"}
	label.style.font = "default-semibold"

	local scroll_pane = frame.add{type="scroll-pane", name="scroll_pane", style="scroll_pane_style", direction="vertical", caption="foo"}
	local table = scroll_pane.add{type="table", name="table", style="table_style", colspan=1}
	table.style.vertical_spacing = -1
	scroll_pane.style.top_padding = 10
	scroll_pane.style.maximal_height = 350
	scroll_pane.style.maximal_width = 500
	scroll_pane.style.minimal_height = 100
	scroll_pane.style.minimal_width = 50

	for index=1, NUM_LINES do
		label = table.add{type="label", style="label_style", name = "text_" .. index, caption="_", single_line=true, want_ellipsis=true}
		label.style.top_padding = 0
		label.style.bottom_padding = 0
		--label.style.font_color = {r=1.0, g=0.7, b=0.9}
	end
end


function CmdUI.update_command_list_ui(player, command_list)
	if not command_list then return end
	if not global.command_list_parser.current_command_group_index or not command_list[global.command_list_parser.current_command_group_index] then return end
	local flow = mod_gui.get_frame_flow(player)
	local frame = flow.command_list_frame

	if not global.command_list_ui then CmdUI.init() end

	if not frame then
		CmdUI.create(player)
		frame = flow.command_list_frame
	end

	-- Visibility
	local show = frame.top_flow.show_command_list_ui_checkbox.state
	if global.command_list_ui.ui_hidden[player.index] ~= not show then
		frame.scroll_pane.style.visible = show
		--frame.type_flow.style.visible = show
		global.command_list_ui.ui_hidden[player.index] = not show
	end

	-- Scheduling
	if game.tick % math.floor(game.speed * 20 + 1) ~= 0 then return end
	if not command_list then return end


	-- Update
	if show then
		local show_passive_commands = frame.top_flow.show_passive_button.state
		local show_spawned_commands = frame.top_flow.show_spawned_button.state
		local current_command_group = command_list[global.command_list_parser.current_command_group_index]
		frame.group_flow.current_command_group.caption = "Active Command Group: " .. current_command_group.name

		local next_command_group = command_list[global.command_list_parser.current_command_group_index + 1]
		if next_command_group then
			if next_command_group.required then
				local s = ""
				for _, name in ipairs(next_command_group.required) do
					if not global.command_list_parser.finished_named_commands[name] then
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

		local command_set_index = 0
		for index = 1, NUM_LINES do
			local command
			repeat
				command_set_index = command_set_index + 1
				command = global.command_list_parser.current_command_set[command_set_index]
			until ( (command and not command.finished 
			and (show_passive_commands or not Utils.in_list(command[1], passive_commands))
			and (show_spawned_commands or not command.spawned_by)) 
			or command_set_index > #global.command_list_parser.current_command_set )

			if command then
				local s = "[" .. index .. "] | "
				for key, value in pairs(command) do
					if not Utils.in_list(key, {"data", "action_type", "tested", "rect", "distance"}) then
						s = s .. key .. "= " .. Utils.printable(value) .. " | "
					end
				end
				local label = frame.scroll_pane.table["text_" .. index]
				label.caption = s
				if command.spawned_by then
					label.style.font_color = {r=0.8, g=0.6, b=0.3, a=1}
				elseif Utils.in_list(command[1], passive_commands) then
					label.style.font_color = {r=0.7, g=0.7, b=0.7, a=1}
				else
					label.style.font_color = {r=1, g=1, b=1, a=1}
				end
			else
				frame.scroll_pane.table["text_" .. index].caption = ""
			end
		end
	end
end

function CmdUI.destroy_command_list_ui(player)
	local fr = mod_gui.get_frame_flow(player).command_list_frame
	if fr and fr.valid then fr.destroy() end
end

return CmdUI