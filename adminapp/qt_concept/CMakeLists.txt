cmake_minimum_required(VERSION 3.16)

project(EingliederungshilfeQt VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Qt6 Components
find_package(Qt6 REQUIRED COMPONENTS
    Core
    Widgets
    Network
    Sql
    Charts
    PrintSupport
)

qt6_standard_project_setup()

# Source Files
set(SOURCES
    src/main.cpp
    src/mainwindow.cpp
    src/core/WebDAVManager.cpp
    src/core/DataManager.cpp
    src/core/EncryptionManager.cpp
    src/core/ConfigManager.cpp
    src/models/Employee.cpp
    src/models/Client.cpp
    src/models/Shift.cpp
    src/models/VacationRequest.cpp
    src/widgets/EmployeeWidget.cpp
    src/widgets/ShiftPlanningWidget.cpp
    src/widgets/CapacityWidget.cpp
    src/widgets/ClientWidget.cpp
    src/dialogs/SetupDialog.cpp
    src/dialogs/EmployeeDialog.cpp
    src/dialogs/SettingsDialog.cpp
)

set(HEADERS
    src/mainwindow.h
    src/core/WebDAVManager.h
    src/core/DataManager.h
    src/core/EncryptionManager.h
    src/core/ConfigManager.h
    src/models/Employee.h
    src/models/Client.h
    src/models/Shift.h
    src/models/VacationRequest.h
    src/widgets/EmployeeWidget.h
    src/widgets/ShiftPlanningWidget.h
    src/widgets/CapacityWidget.h
    src/widgets/ClientWidget.h
    src/dialogs/SetupDialog.h
    src/dialogs/EmployeeDialog.h
    src/dialogs/SettingsDialog.h
)

# UI Files
set(UI_FILES
    ui/mainwindow.ui
    ui/setupdialog.ui
    ui/employeedialog.ui
    ui/settingsdialog.ui
)

# Resource Files
set(RESOURCE_FILES
    resources/icons.qrc
    resources/styles.qrc
    resources/translations.qrc
)

# Create executable
qt6_add_executable(EingliederungshilfeQt ${SOURCES} ${HEADERS})

# Add UI files
qt6_add_resources(EingliederungshilfeQt ${RESOURCE_FILES})

# Link Qt libraries
target_link_libraries(EingliederungshilfeQt
    Qt6::Core
    Qt6::Widgets
    Qt6::Network
    Qt6::Sql
    Qt6::Charts
    Qt6::PrintSupport
)

# Include directories
target_include_directories(EingliederungshilfeQt PRIVATE
    src
    src/core
    src/models
    src/widgets
    src/dialogs
)

# Compiler definitions
target_compile_definitions(EingliederungshilfeQt PRIVATE
    QT_NO_DEBUG_OUTPUT
    APP_VERSION="${PROJECT_VERSION}"
)

# Platform-specific settings
if(WIN32)
    set_target_properties(EingliederungshilfeQt PROPERTIES
        WIN32_EXECUTABLE TRUE
    )
    # Windows-specific icons and resources
    target_sources(EingliederungshilfeQt PRIVATE resources/app.rc)
endif()

if(APPLE)
    set_target_properties(EingliederungshilfeQt PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/resources/Info.plist
    )
endif()

# Installation
include(GNUInstallDirs)

install(TARGETS EingliederungshilfeQt
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

# Create installer package
if(WIN32)
    # NSIS installer for Windows
    set(CPACK_GENERATOR "NSIS")
    set(CPACK_PACKAGE_NAME "Eingliederungshilfe Admin")
    set(CPACK_PACKAGE_VENDOR "Ihr Unternehmen")
    set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
    set(CPACK_PACKAGE_INSTALL_DIRECTORY "EingliederungshilfeQt")

    include(CPack)
endif()

if(APPLE)
    # DMG installer for macOS
    set(CPACK_GENERATOR "DragNDrop")
    set(CPACK_BUNDLE_NAME "Eingliederungshilfe Admin")

    include(CPack)
endif()