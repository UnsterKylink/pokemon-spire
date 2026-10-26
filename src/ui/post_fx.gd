class_name PostFx
extends CanvasLayer
## Story 020b — global image finish (art bible §8): a CanvasLayer above every screen holding one full-screen
## ColorRect with post_finish.gdshader (soft halo of bright areas, gentle colour grade, vignette, light film grain).
## Reads the screen texture, ignores the mouse, owns no game state. Added once by Main (internal child).
## Budget: 1 draw call + 1 screen copy per frame, 13 texture reads per pixel (desktop 1280x720).

const LAYER: int = 120
const SHADER_PATH: String = "res://src/ui/shaders/post_finish.gdshader"

var _rect: ColorRect
var _material: ShaderMaterial


func _init() -> void:
	name = "PostFx"
	layer = LAYER
	_rect = ColorRect.new()
	_rect.name = "Finish"
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.color = Color.WHITE
	if ResourceLoader.exists(SHADER_PATH):
		_material = ShaderMaterial.new()
		_material.shader = load(SHADER_PATH) as Shader
		_material.set_shader_parameter("noise_tex", UiStyle.ui_texture("ui_noise"))
		_rect.material = _material
	else:
		_rect.visible = false
	add_child(_rect)


## Turns the whole finish on / off (e.g. a future graphics option).
func set_enabled(on: bool) -> void:
	_rect.visible = on and _material != null


## True when the finish is drawn.
func is_enabled() -> bool:
	return _rect.visible


## Sets one post_finish.gdshader uniform (halo_strength, saturation, contrast, vignette_strength, grain_strength...).
func set_param(param: String, value: Variant) -> void:
	if _material != null:
		_material.set_shader_parameter(param, value)
