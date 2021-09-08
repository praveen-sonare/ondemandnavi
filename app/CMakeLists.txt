qt5_add_resources(RESOURCES navigation.qrc images/images.qrc)

set(
    SOURCES file_operation.cpp file_operation.h guidance_module.h main.cpp
        markermodel.h
)

add_executable(navigation ${SOURCES} ${RESOURCES})

target_compile_options(navigation
    PUBLIC ${QTAPPFW_NAVIGATION_COMPILE_OPTIONS}
)
target_include_directories(navigation
    PUBLIC ${QTAPPFW_NAVIGATION_INCLUDE_DIRS}
)
target_link_libraries(navigation
    ${QTAPPFW_NAVIGATION_LIBRARIES} Qt5::Core Qt5::Qml Qt5::Quick Qt5::Location Qt5::Widgets
)

install(TARGETS navigation DESTINATION bin)
