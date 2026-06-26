package j2d

SHADER_DEFAULT_VERT: Shader
SHADER_DEFAULT_FRAG: Shader
SHADER_TEXTURE_FRAG: Shader
SHADER_SDF:          Shader

@private
load_builtin_shaders :: proc() -> bool {
	SHADER_DEFAULT_VERT = create_shader({
		stage = .Vertex,
		glsl = GL_SHADER_DEFAULT_VERT,
	}) or_return

	SHADER_DEFAULT_FRAG = create_shader({
		stage = .Fragment,
		glsl = GL_SHADER_COLOR_FRAG,
	}) or_return

	SHADER_TEXTURE_FRAG = create_shader({
		stage = .Fragment,
		glsl = GL_SHADER_TEXTURE_FRAG,
	}) or_return

	SHADER_SDF = create_shader({
		stage = .Fragment,
		glsl = GL_SHADER_SDF_FRAG,
	}) or_return

	return true
}
