extends RefCounted
## Reads either a trackr ZIP or an extracted sequence.json. No editor plugin required.

static func read(path: String) -> Dictionary:
	var archive: ZIPReader
	var manifest_path := path
	var text: String
	if path.get_extension().to_lower() == "zip":
		archive = ZIPReader.new()
		if archive.open(path) != OK:
			return {"error": "Could not open sequence ZIP: " + path}
		if not archive.file_exists("sequence.json"):
			archive.close()
			return {"error": "The ZIP does not contain sequence.json at its root."}
		text = archive.read_file("sequence.json").get_string_from_utf8()
	else:
		if path.get_extension().to_lower() != "json":
			manifest_path = path.path_join("sequence.json")
		var file := FileAccess.open(manifest_path, FileAccess.READ)
		if file == null:
			return {"error": "Could not open sequence manifest: " + manifest_path}
		text = file.get_as_text()
	var json := JSON.new()
	var problem := ""
	if json.parse(text) != OK:
		problem = "Invalid sequence JSON: " + json.get_error_message()
	elif not json.data is Dictionary:
		problem = "The sequence manifest must be an object."
	else:
		problem = _validate(json.data)
	if not problem.is_empty():
		if archive != null:
			archive.close()
		return {"error": problem}
	var data: Dictionary = json.data
	var streams := {}
	for sample: Dictionary in data.samples:
		var stream: AudioStreamWAV
		if archive != null:
			if archive.file_exists(sample.file):
				stream = AudioStreamWAV.load_from_buffer(archive.read_file(sample.file), _wav_options())
		else:
			var sample_path: String = manifest_path.get_base_dir().path_join(sample.file)
			# Imported res:// WAVs are remapped in a built game; user:// WAVs are raw files.
			if sample_path.begins_with("res://") and ResourceLoader.exists(sample_path, "AudioStreamWAV"):
				var resource := ResourceLoader.load(sample_path) as AudioStreamWAV
				if resource != null:
					stream = resource.duplicate() as AudioStreamWAV
			elif FileAccess.file_exists(sample_path):
				stream = AudioStreamWAV.load_from_file(sample_path, _wav_options())
		if stream == null:
			problem = "Could not load WAV sample: " + str(sample.file)
			break
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
		if sample.has("loop"):
			if sample.loop.end > stream.get_length() + 0.001:
				problem = "Sample loop exceeds the WAV length: " + str(sample.file)
				break
			stream.loop_begin = roundi(float(sample.loop.start) * stream.mix_rate)
			stream.loop_end = mini(roundi(float(sample.loop.end) * stream.mix_rate), roundi(stream.get_length() * stream.mix_rate))
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		streams[sample.id] = stream
	if archive != null:
		archive.close()
	if not problem.is_empty():
		return {"error": problem}
	var rows := {}
	for pattern: Dictionary in data.patterns:
		var pattern_rows: Array = []
		for row in int(pattern.row_count):
			pattern_rows.append([])
		for event: Dictionary in pattern.events:
			pattern_rows[int(event.row)].append(event)
		rows[pattern.id] = pattern_rows
	return {"data": data, "streams": streams, "rows": rows}

static func _wav_options() -> Dictionary:
	return {"edit/normalize": false, "edit/trim": false, "edit/loop_mode": 0, "compress/mode": 0}

static func _number(value: Variant, low: float, high: float) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and value >= low and value <= high

static func _integer(value: Variant, low: int, high: int) -> bool:
	return _number(value, low, high) and value == floor(value)

static func _validate(data: Dictionary) -> String:
	if data.get("format") != "trackr-sequence" or data.get("version") != 1:
		return "Unsupported sequence format or version."
	if not _number(data.get("bpm"), 1, 10000) or not _integer(data.get("rows_per_beat"), 1, 64):
		return "Invalid sequence tempo."
	if not data.get("loop") is bool or not _number(data.get("master_gain"), 0, 2):
		return "Invalid sequence playback settings."
	if not data.get("tracks") is Array or data.tracks.is_empty() or data.tracks.size() > 16:
		return "A sequence must contain 1–16 tracks."
	for track in data.tracks:
		if not track is Dictionary or not _number(track.get("volume"), 0, 1) or not _number(track.get("pan"), -1, 1):
			return "Invalid track mixer settings."
	if not data.get("samples") is Array or data.samples.size() > 4096:
		return "Invalid sequence sample list."
	var sample_ids := {}
	for sample in data.samples:
		if not sample is Dictionary or not sample.get("id") is String or sample.id.is_empty() or sample_ids.has(sample.id):
			return "Invalid or duplicate sample ID."
		var file: Variant = sample.get("file")
		if not file is String or not file.begins_with("samples/") or file.contains("..") or file.contains(":") or file.contains("\\") or file.get_extension().to_lower() != "wav":
			return "Sample files must be relative WAV paths under samples/."
		if not _integer(sample.get("root_note"), 0, 119) or not _number(sample.get("gain"), 0, 2):
			return "Invalid sample tuning or gain."
		if not _number(sample.get("attack"), 0.001, 5) or not _number(sample.get("release"), 0.001, 5):
			return "Invalid sample envelope."
		if sample.has("loop"):
			if not sample.loop is Dictionary or not _number(sample.loop.get("start"), 0, 3600) or not _number(sample.loop.get("end"), 0, 3600) or sample.loop.end <= sample.loop.start:
				return "Invalid sample loop."
		sample_ids[sample.id] = true
	if not data.get("patterns") is Array or data.patterns.is_empty() or data.patterns.size() > 128:
		return "Invalid pattern list."
	var pattern_ids := {}
	for pattern in data.patterns:
		if not pattern is Dictionary or not pattern.get("id") is String or pattern.id.is_empty() or pattern_ids.has(pattern.id):
			return "Invalid or duplicate pattern ID."
		if not _integer(pattern.get("row_count"), 1, 64) or not pattern.get("events") is Array:
			return "Invalid pattern rows."
		var cells := {}
		for event in pattern.events:
			if not event is Dictionary or not _integer(event.get("row"), 0, int(pattern.row_count) - 1) or not _integer(event.get("track"), 0, data.tracks.size() - 1):
				return "Invalid event position."
			var cell := "%d:%d" % [event.row, event.track]
			if cells.has(cell):
				return "More than one event occupies a pattern cell."
			cells[cell] = true
			if event.get("op") == "note_on":
				if not event.get("sample") is String or not sample_ids.has(event.sample) or not _integer(event.get("note"), 0, 119) or not _number(event.get("volume"), 0, 100):
					return "Invalid note or missing sample reference."
			elif event.get("op") != "note_off":
				return "Unknown sequence event."
		pattern_ids[pattern.id] = true
	if not data.get("order") is Array or data.order.is_empty() or data.order.size() > 256:
		return "Invalid song order."
	for id in data.order:
		if not id is String or not pattern_ids.has(id):
			return "Song order references a missing pattern."
	return ""
