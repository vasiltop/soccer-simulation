extends Node

func get_min_index(array: Array) -> int:
	var min_value = array[0] 
	var min_index = 0  

	for i in range(1, array.size()):
		if array[i] < min_value:
			min_value = array[i]
			min_index = i

	return min_index

func get_max_index(array: Array) -> int:
	var max_value = array[0]
	var max_index = 0

	for i in range(1, array.size()):
		if array[i] > max_value:
			max_value = array[i]
			max_index = i

	return max_index
