include (Translations) # Replace plug-name with the correct name of your plug
add_translations_directory("${PLUGNAME}")
add_translations_catalog("${PLUGNAME}"
    ../src/
)
