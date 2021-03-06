(** SHA256 OCaml binding
 **)

type ctx
type buf = (int, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t
type t

external init: unit -> ctx = "stub_sha256_init"
external unsafe_update_substring: ctx -> string -> int -> int -> unit = "stub_sha256_update"
external update_buffer: ctx -> buf -> unit = "stub_sha256_update_bigarray"
external finalize: ctx -> t = "stub_sha256_finalize"
external copy : ctx -> ctx = "stub_sha256_copy"
external to_bin: t -> string = "stub_sha256_to_bin"
external to_hex: t -> string = "stub_sha256_to_hex"
external file_fast: string -> t = "stub_sha256_file"

let blksize = 4096

let update_substring ctx s ofs len =
	if len <= 0 && String.length s < ofs + len then
		invalid_arg "substring";
	unsafe_update_substring ctx s ofs len

let update_string ctx s =
	unsafe_update_substring ctx s 0 (String.length s)

external update_bigarray: ctx -> (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t -> unit = "stub_sha256_update_bigarray"

let string s =
	let ctx = init () in
	unsafe_update_substring ctx s 0 (String.length s);
	finalize ctx

let zero = string ""

let substring s ofs len =
	if len <= 0 && String.length s < ofs + len then
		invalid_arg "substring";
	let ctx = init () in
	unsafe_update_substring ctx s ofs len;
	finalize ctx

let buffer buf =
	let ctx = init () in
	update_buffer ctx buf;
	finalize ctx

let channel chan len =
	let ctx = init ()
	and buf = String.create blksize in

	let left = ref len and eof = ref false in
	while (!left == -1 || !left > 0) && not !eof
	do
		let len = if !left < 0 then blksize else (min !left blksize) in
		let readed = Pervasives.input chan buf 0 len in
		if readed = 0 then
			eof := true
		else (
			unsafe_update_substring ctx buf 0 readed;
			if !left <> -1 then left := !left - readed
		)
	done;
	if !left > 0 && !eof then
		raise End_of_file;
	finalize ctx

let file name =
	let chan = open_in_bin name in
	let digest = channel chan (-1) in
	close_in chan;
	digest

let input chan =
	channel chan (-1)

let output chan digest =
	output_string chan (to_hex digest)
