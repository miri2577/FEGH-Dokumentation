#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QTabWidget>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QMenuBar>
#include <QStatusBar>
#include <QToolBar>
#include <QPushButton>
#include <QLabel>
#include <QProgressBar>
#include <QTimer>
#include <QSystemTrayIcon>

// Core Components
#include "core/WebDAVManager.h"
#include "core/DataManager.h"
#include "core/ConfigManager.h"

// Widgets
#include "widgets/EmployeeWidget.h"
#include "widgets/ClientWidget.h"
#include "widgets/ShiftPlanningWidget.h"
#include "widgets/CapacityWidget.h"

// Dialogs
#include "dialogs/SetupDialog.h"
#include "dialogs/SettingsDialog.h"

QT_BEGIN_NAMESPACE
class QAction;
class QSplitter;
QT_END_NAMESPACE

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

protected:
    void closeEvent(QCloseEvent *event) override;

private slots:
    // Menu Actions
    void newFile();
    void openFile();
    void saveFile();
    void saveAsFile();
    void exportData();
    void importData();
    void showPreferences();
    void showAbout();

    // Connection Management
    void onConnectionStatusChanged(bool connected);
    void onSyncCompleted();
    void onSyncFailed(const QString &error);
    void onDataLoaded(const QString &dataType, const QJsonObject &data);

    // UI Updates
    void updateStatusBar();
    void updateWindowTitle();
    void onTabChanged(int index);

    // System Tray
    void onTrayIconActivated(QSystemTrayIcon::ActivationReason reason);
    void showMainWindow();
    void minimizeToTray();

    // Auto-save
    void autoSave();

private:
    void setupUI();
    void setupMenuBar();
    void setupToolBar();
    void setupStatusBar();
    void setupSystemTray();
    void setupConnections();
    void loadSettings();
    void saveSettings();
    bool ensureConnection();

    // UI Components
    QTabWidget *m_tabWidget;
    QSplitter *m_mainSplitter;

    // Tab Widgets
    EmployeeWidget *m_employeeWidget;
    ClientWidget *m_clientWidget;
    ShiftPlanningWidget *m_shiftPlanningWidget;
    CapacityWidget *m_capacityWidget;

    // Menu Actions
    QAction *m_newAction;
    QAction *m_openAction;
    QAction *m_saveAction;
    QAction *m_saveAsAction;
    QAction *m_exportAction;
    QAction *m_importAction;
    QAction *m_exitAction;
    QAction *m_preferencesAction;
    QAction *m_aboutAction;
    QAction *m_syncAction;
    QAction *m_connectAction;

    // Toolbar
    QToolBar *m_mainToolBar;
    QPushButton *m_syncButton;
    QPushButton *m_connectionButton;

    // Status Bar
    QLabel *m_connectionLabel;
    QLabel *m_lastSyncLabel;
    QProgressBar *m_progressBar;

    // System Tray
    QSystemTrayIcon *m_trayIcon;
    QMenu *m_trayMenu;

    // Core Managers
    WebDAVManager *m_webdavManager;
    DataManager *m_dataManager;
    ConfigManager *m_configManager;

    // State
    bool m_isConnected;
    bool m_hasUnsavedChanges;
    QString m_currentFileName;
    QTimer *m_autoSaveTimer;
    QTimer *m_statusUpdateTimer;

    // Professional Features
    enum class Theme {
        Light,
        Dark,
        Auto
    };
    Theme m_currentTheme;

    void applyTheme(Theme theme);
    void setupProfessionalStyling();
    void updateConnectionIndicator();
    void showConnectionDialog();
};

#endif // MAINWINDOW_H