extends RefCounted
## Lua scalar conversions used by source-backed UI contracts, not save validation.
static func truth(value) -> bool:return value!=null and not (value is bool and not value)
static func text(value,fallback="") -> String:
	if not truth(value):return fallback
	if (value is float or value is int) and value==floor(value):return str(int(value))
	return str(value)
static func number(value,fallback: float=0) -> float:
	if value is int or value is float:return float(value)
	if value is String:
		var s=value.strip_edges()
		if s.is_valid_float():return float(s)
		if s.is_valid_hex_number(true):return float(s.hex_to_int())
	return fallback
static func integer(value,fallback: int=0) -> int:
	var n=number(value,fallback)
	return int(floor(n)) if is_finite(n) else fallback
static func equal_number(value,n: int) -> bool:return (value is int or value is float) and value==n
