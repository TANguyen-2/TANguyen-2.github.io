extends RichTextLabel


func _ready() -> void:
    meta_clicked.connect(on_link_clicked)
    pass


func on_link_clicked(meta: Variant) -> void:
    OS.shell_open(str(meta))
    pass