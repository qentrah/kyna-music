cmake_minimum_required(VERSION 3.25)
project(KynaMusic LANGUAGES CXX)
find_package(Qt6 6.8 REQUIRED COMPONENTS Quick QuickControls2 Multimedia)
find_package(Python3 REQUIRED COMPONENTS Interpreter)
set(CMAKE_AUTOMOC ON)
set(KYNA_ROOT "" CACHE PATH "Kyna source checkout for its public native ABI headers")
if(NOT EXISTS "${KYNA_ROOT}/library/native/include/kyna/native/adapter.hpp")
 message(FATAL_ERROR "Set KYNA_ROOT to the pinned Kyna source checkout")
endif()
set(APP_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/..")
execute_process(COMMAND "${Python3_EXECUTABLE}" "${APP_ROOT}/tools/generate_demo.py" "${CMAKE_CURRENT_BINARY_DIR}/demo" COMMAND_ERROR_IS_FATAL ANY)
add_library(music_bridge MODULE
 src/bindings/native_exports.cpp
 src/ui/music_bridge.cpp src/ui/music_bridge.hpp
 src/playback/audio_player.cpp
 src/storage/library_store.cpp
 src/platform/gui_runtime_paths.cpp
 src/platform/gui_module_lifetime.cpp)
target_compile_features(music_bridge PRIVATE cxx_std_20)
target_include_directories(music_bridge PRIVATE "${KYNA_ROOT}/library/native/include" "${KYNA_ROOT}/sdk/kyna_embedding/include" "${CMAKE_CURRENT_SOURCE_DIR}/src/platform")
target_link_libraries(music_bridge PRIVATE Qt6::Quick Qt6::QuickControls2 Qt6::Multimedia ${CMAKE_DL_LIBS})
set_target_properties(music_bridge PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/native" RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/native")
qt_add_resources(music_bridge "music_ui" PREFIX "/music" BASE "${APP_ROOT}" FILES
 "${APP_ROOT}/ui/Main.qml" "${APP_ROOT}/ui/IconButton.qml" "${APP_ROOT}/ui/TrackRow.qml"
 "${APP_ROOT}/ui/AlbumCard.qml" "${APP_ROOT}/ui/PlayerBar.qml"
 "${APP_ROOT}/ui/icons/app.svg" "${APP_ROOT}/ui/icons/home.svg" "${APP_ROOT}/ui/icons/search.svg" "${APP_ROOT}/ui/icons/library.svg"
 "${APP_ROOT}/ui/icons/plus.svg" "${APP_ROOT}/ui/icons/play.svg" "${APP_ROOT}/ui/icons/pause.svg"
 "${APP_ROOT}/ui/icons/next.svg" "${APP_ROOT}/ui/icons/previous.svg" "${APP_ROOT}/ui/icons/heart.svg"
 "${APP_ROOT}/ui/icons/heart-filled.svg" "${APP_ROOT}/ui/icons/shuffle.svg" "${APP_ROOT}/ui/icons/repeat.svg"
 "${APP_ROOT}/ui/icons/volume.svg" "${APP_ROOT}/ui/icons/queue.svg" "${APP_ROOT}/ui/icons/close.svg"
 "${APP_ROOT}/ui/icons/import.svg" "${APP_ROOT}/ui/icons/arrow.svg" "${APP_ROOT}/ui/icons/more.svg"
 "${APP_ROOT}/ui/art/01.svg" "${APP_ROOT}/ui/art/02.svg" "${APP_ROOT}/ui/art/03.svg"
 "${APP_ROOT}/ui/art/04.svg" "${APP_ROOT}/ui/art/05.svg" "${APP_ROOT}/ui/art/06.svg")
qt_add_resources(music_bridge "music_demo" PREFIX "/music/demo" BASE "${CMAKE_CURRENT_BINARY_DIR}/demo" FILES
 "${CMAKE_CURRENT_BINARY_DIR}/demo/catalog.json"
 "${CMAKE_CURRENT_BINARY_DIR}/demo/01.wav" "${CMAKE_CURRENT_BINARY_DIR}/demo/02.wav"
 "${CMAKE_CURRENT_BINARY_DIR}/demo/03.wav" "${CMAKE_CURRENT_BINARY_DIR}/demo/04.wav"
 "${CMAKE_CURRENT_BINARY_DIR}/demo/05.wav" "${CMAKE_CURRENT_BINARY_DIR}/demo/06.wav")

add_executable(music_launcher WIN32 src/entry/music_launcher.cpp)
target_compile_features(music_launcher PRIVATE cxx_std_20)
if(WIN32)
 target_link_libraries(music_launcher PRIVATE user32)
endif()
add_executable(music_icon_renderer src/packaging/icon_renderer.cpp)
target_compile_features(music_icon_renderer PRIVATE cxx_std_20)
target_link_libraries(music_icon_renderer PRIVATE Qt6::Gui)
if(WIN32)
 enable_language(RC)
 add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/music.ico"
  COMMAND music_icon_renderer "${APP_ROOT}/ui/icons/app.svg" "${CMAKE_CURRENT_BINARY_DIR}/music.ico" 256
  DEPENDS music_icon_renderer "${APP_ROOT}/ui/icons/app.svg")
 file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/music.rc" "1 ICON \"${CMAKE_CURRENT_BINARY_DIR}/music.ico\"\n")
 set_source_files_properties("${CMAKE_CURRENT_BINARY_DIR}/music.rc" PROPERTIES OBJECT_DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/music.ico")
 target_sources(music_launcher PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/music.rc" "${CMAKE_CURRENT_BINARY_DIR}/music.ico")
endif()
