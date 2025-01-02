extends Control

var checkboxes: Array[CheckBox]
var elevation_slider: HSlider

signal color_selected(color)
signal elevation_set(elevation)

func _ready():
	checkboxes.append($YellowCheckBox)
	checkboxes.append($GreenCheckBox)
	checkboxes.append($BlueCheckBox) 
	checkboxes.append($WhiteCheckBox)
	
	for i in checkboxes.size():
		checkboxes[i].mouse_filter = Control.MOUSE_FILTER_STOP
		checkboxes[i].connect('toggled', Callable(_on_checkbox_toggled).bind(checkboxes[i]))
	
	elevation_slider = $ElevationSlider
	elevation_slider.mouse_filter = Control.MOUSE_FILTER_STOP
	elevation_slider.connect('value_changed', _on_slider_changed)

func _on_checkbox_toggled(checked: bool, checkbox:CheckBox) -> void:
	if checked:
		var picked_color:Color
		match (checkbox.name):
			'YellowCheckBox':
				picked_color = Color.YELLOW
			'GreenCheckBox':
				picked_color = Color.GREEN
			'BlueCheckBox':
				picked_color = Color.AQUA
			_:
				picked_color = Color(0.5,0.5,0.5)
		color_selected.emit(picked_color)

func _on_slider_changed(elevation_value: float):
	elevation_set.emit(elevation_value)
