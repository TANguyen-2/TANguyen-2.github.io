@tool
extends Resource
class_name NodePool


var creation_function: Callable
var pooled_instances: Array[Node] = []


func get_instance() -> Node:
    if pooled_instances.is_empty():
        return creation_function.call()
    else:
        return pooled_instances.pop_back()


func pool_instance(released_node: Node) -> void:
    pooled_instances.append(released_node)
    pass


func clear_pooled_instances() -> void:
    pooled_instances.clear()
    pass
