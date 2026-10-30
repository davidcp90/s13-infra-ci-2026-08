#!/usr/bin/env bash
# PostToolUse (Write|Edit): AVISA (exit 2) cuando, tras tocar un archivo de
# .github/workflows/, los workflows dejan de pasar actionlint.
#
# Valida con `make ci-lint`, el mismo atajo que llama el trabajo
# `lint-workflows` de ci.yml: lo que aquí pasa, pasa en el pipeline, y al revés.
# Revisa todo el directorio y no solo el archivo tocado, porque eso es lo que
# hace el pipeline.
#
# AVISA, NO BLOQUEA. En PostToolUse la herramienta ya ha escrito el archivo, así
# que el exit 2 no deshace nada: solo le pone delante a quien escribió qué
# archivo tocó y qué dijo actionlint.
#
# Necesita Docker en marcha. Si no lo está, `make ci-lint` falla igual y el
# aviso trae el error de Docker en vez del de actionlint.

set -uo pipefail

entrada=$(cat)

archivo=$(printf '%s' "$entrada" | jq -r '.tool_response.filePath // .tool_input.file_path // empty')
[ -n "$archivo" ] || exit 0

proyecto="${CLAUDE_PROJECT_DIR:-$(pwd)}"

case "$archivo" in
  "$proyecto"/.github/workflows/*) ;;
  *) exit 0 ;;
esac

# `-color` es para la terminal; aquí lo lee quien escribió, así que fuera los
# códigos ANSI.
salida=$(make -C "$proyecto" --no-print-directory ci-lint 2>&1) && exit 0
salida=$(printf '%s' "$salida" | sed -E $'s/\x1b\\[[0-9;]*m//g')

{
  echo "AVISO de workflow-valido.sh tras tocar ${archivo#"$proyecto"/}:"
  echo "\`make ci-lint\` (actionlint, el mismo comando que el trabajo lint-workflows de ci.yml) ha fallado:"
  echo
  printf '%s\n' "$salida"
  echo
  echo "Por qué: un workflow mal escrito no se ve hasta que el pipeline lo rechaza o, peor, hasta que se salta un trabajo sin decir nada."
  echo "Qué hacer: corrige lo que señala actionlint y vuelve a pasar \`make ci-lint\`. Esto avisa, no bloquea."
} >&2
exit 2
