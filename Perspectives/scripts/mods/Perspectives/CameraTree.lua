local mod = get_mod("Perspectives")
local CameraSettings = require("scripts/settings/camera/camera_settings")

local FOV_NORMAL = 62.5
local FOV_ZOOM = 55.0
local CUSTOM_MULT = 0.75

local custom_distance = 0.0
local custom_offset = 0.0
local custom_distance_zoom = 0.0
local custom_offset_zoom = 0.0

-- +x/-x = right/left
-- +y/-y = forward/back
-- +z/-z = up/down
local OFFSET_TO_OGRYN = {
	x = 0.0,
	y = -0.75,
	z = -0.1,
}

-- flip is either true (flip), false (don't flip), or nil (it's a center viewpoint)
local _transform_offset = function(offset, flip, is_zoom, ignore_custom_offset)
	if is_zoom then
		offset.y = offset.y + custom_distance - custom_distance_zoom
	end

	if not ignore_custom_offset then
		local offset_amt = is_zoom and (custom_offset_zoom - custom_offset) or custom_offset
		if flip == nil then
			offset.z = offset.z + offset_amt
		else
			offset.x = offset.x + offset_amt
		end
	end

	if flip then
		offset.x = -offset.x
	end

	return offset
end

local _get_shoulder_offset = function(left)
	return _transform_offset({
		x = 0.5,
		y = 0,
		z = 0,
	}, left)
end

local _get_shoulder_zoom_offset = function(left)
	return _transform_offset({
		x = -0.1,
		y = 0.65,
		z = -0.1,
	}, left, true)
end

local _get_shoulder_ogryn_offset = function(left)
	return _transform_offset({
		x = OFFSET_TO_OGRYN.x + 0.5,
		y = OFFSET_TO_OGRYN.y + 0.0,
		z = OFFSET_TO_OGRYN.z + 0.0,
	}, left, false, true)
end

local _get_shoulder_zoom_ogryn_offset = function(left)
	return _transform_offset({
		x = -0.1,
		y = 0.65,
		z = 0.0,
	}, left, true)
end

local _node_get_child_idx = function(node, child_name)
	for i, n in pairs(node) do
		if i ~= "_node" then
			if n._node.name == child_name then
				return i
			end
		end
	end
	return #node + 1
end

local _node_add_child = function(parent, child)
	parent[_node_get_child_idx(parent, child._node.name)] = child
end

local _create_node = function(name, offset, fov)
	return {
		near_range = 0.025,
		name = name,
		class = "TransformCamera",
		custom_vertical_fov = fov,
		vertical_fov = fov,
		offset_position = offset
	}
end

local function _alter_third_person_tree(node)
	if node then
		if node._node.name == "third_person" then
			_node_add_child(node, {
				{
					{
						{
							_node = _create_node("pspv_right_zoom_ogryn", _get_shoulder_zoom_ogryn_offset(false), FOV_ZOOM)
						},
						_node = _create_node("pspv_right_ogryn", _get_shoulder_ogryn_offset(false))
					},
					{
						_node = _create_node("pspv_right_zoom", _get_shoulder_zoom_offset(false), FOV_ZOOM)
					},
					_node = _create_node("pspv_right", _get_shoulder_offset(false))
				},
				{
					{
						{
							_node = _create_node("pspv_left_zoom_ogryn", _get_shoulder_zoom_ogryn_offset(true), FOV_ZOOM)
						},
						_node = _create_node("pspv_left_ogryn", _get_shoulder_ogryn_offset(true))
					},
					{
						_node = _create_node("pspv_left_zoom", _get_shoulder_zoom_offset(true), FOV_ZOOM)
					},
					_node = _create_node("pspv_left", _get_shoulder_offset(true))
				},
				{
					{
						{
							_node = _create_node("pspv_center_zoom_ogryn", _transform_offset({
								x = 0.0,
								y = 1.8,
								z = -0.2,
							}, nil, true), FOV_ZOOM)
						},
						_node = _create_node("pspv_center_ogryn", _transform_offset(OFFSET_TO_OGRYN, nil, false, true))
					},
					{
						_node = _create_node("pspv_center_zoom", _transform_offset({
							x = 0.0,
							y = 1.0,
							z = -0.3,
						}, nil, true), FOV_ZOOM)
					},
					_node = _create_node("pspv_center", _transform_offset({
						x = 0.0,
						y = 0.0,
						z = 0.2,
					}, nil))
				},
				{
					{
						_node = _create_node("pspv_lookaround_ogryn", OFFSET_TO_OGRYN)
					},
					_node = _create_node("pspv_lookaround", {
						x = 0.0,
						y = -0.5,
						z = -0.5,
					})
				},
				_node = _create_node("pspv_root", {
					x = 0.0,
					y = 0.5 - custom_distance,
					z = -0.1,
				}, FOV_NORMAL)
			})
		end

		for i, n in pairs(node) do
			if i ~= "_node" then
				_alter_third_person_tree(n)
			end
		end
	end
end


local _refresh_camera_trees = function()
	_alter_third_person_tree(CameraSettings.player_third_person)
	local camera_handler = mod.get_camera_handler()
	if camera_handler then
		camera_handler:on_reload()
	end
end
_refresh_camera_trees()

mod.apply_custom_viewpoint = function(distance, offset, distance_zoom, offset_zoom)
	custom_distance = distance * CUSTOM_MULT
	custom_offset = offset * CUSTOM_MULT
	custom_distance_zoom = distance_zoom * CUSTOM_MULT
	custom_offset_zoom = offset_zoom * CUSTOM_MULT
	_refresh_camera_trees()
end
