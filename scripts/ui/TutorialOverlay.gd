extends Control

@onready var title_label: Label = %TitleLabel
@onready var body_label: RichTextLabel = %BodyLabel
@onready var progress_label: Label = %ProgressLabel
@onready var next_button: Button = %NextButton

var steps: Array = []
var current_index := 0

func _ready() -> void:
	steps = ConfigRepository.tutorial.get("steps", [])
	var tutorial := PlayerState.get_tutorial()
	current_index = int(tutorial.get("step_index", 0))
	_refresh()

func _refresh() -> void:
	if steps.is_empty():
		title_label.text = "Обучение"
		body_label.text = "Шаги обучения пока не загружены."
		progress_label.text = "0 / 0"
		next_button.disabled = true
		return
	current_index = clamp(current_index, 0, steps.size() - 1)
	var step := steps[current_index]
	title_label.text = str(step.get("title", "Шаг"))
	body_label.text = str(step.get("body", ""))
	progress_label.text = "%d / %d" % [current_index + 1, steps.size()]
	next_button.text = "Завершить" if current_index >= steps.size() - 1 else "Далее"

func _on_next_pressed() -> void:
	if current_index >= steps.size() - 1:
		PlayerState.complete_tutorial()
		queue_free()
		return
	current_index += 1
	PlayerState.set_tutorial_step(current_index)
	_refresh()

func _on_skip_pressed() -> void:
	PlayerState.complete_tutorial()
	queue_free()
