#ifndef SHIFTPLANNINGWIDGET_H
#define SHIFTPLANNINGWIDGET_H

#include <QWidget>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGridLayout>
#include <QScrollArea>
#include <QCalendarWidget>
#include <QTableWidget>
#include <QLabel>
#include <QPushButton>
#include <QComboBox>
#include <QLineEdit>
#include <QSpinBox>
#include <QDateEdit>
#include <QTimeEdit>
#include <QGroupBox>
#include <QFrame>
#include <QPainter>
#include <QTimer>
#include <QMenu>
#include <QContextMenuEvent>
#include <QDragEnterEvent>
#include <QDropEvent>
#include <QMimeData>

#include "models/Employee.h"
#include "models/Shift.h"
#include "models/VacationRequest.h"

QT_BEGIN_NAMESPACE
class QSplitter;
class QStackedWidget;
QT_END_NAMESPACE

class ShiftPlanningWidget : public QWidget
{
    Q_OBJECT

public:
    explicit ShiftPlanningWidget(QWidget *parent = nullptr);
    ~ShiftPlanningWidget();

    enum ViewMode {
        WeekView,
        MonthView,
        DayView
    };

    enum DisplayMode {
        Compact,
        Detailed,
        Overview
    };

    // Public interface
    void setEmployees(const QList<Employee> &employees);
    void setShifts(const QList<Shift> &shifts);
    void setVacationRequests(const QList<VacationRequest> &vacations);
    void refreshView();

signals:
    void shiftCreated(const Shift &shift);
    void shiftModified(const Shift &shift);
    void shiftDeleted(const QString &shiftId);
    void employeeAssigned(const QString &shiftId, const QString &employeeId);
    void capacityAlertTriggered(const QString &message, int severity);

protected:
    void paintEvent(QPaintEvent *event) override;
    void contextMenuEvent(QContextMenuEvent *event) override;
    void dragEnterEvent(QDragEnterEvent *event) override;
    void dropEvent(QDropEvent *event) override;

private slots:
    void onViewModeChanged();
    void onDisplayModeChanged();
    void onDateChanged(const QDate &date);
    void onEmployeeFilterChanged();
    void onDepartmentFilterChanged();
    void onCreateShift();
    void onEditShift();
    void onDeleteShift();
    void onCopyShift();
    void onShiftDoubleClicked();
    void onCapacityAnalysis();
    void onExportView();
    void onPrintView();
    void updateAlerts();

private:
    void setupUI();
    void setupToolbar();
    void setupCalendarView();
    void setupShiftGrid();
    void setupAlertPanel();
    void setupColorLegend();
    void setupFilters();

    // View Management
    void updateShiftGrid();
    void updateCalendarHighlights();
    void updateCapacityIndicators();
    void updateColorLegend();

    // Professional Features
    void drawShiftCell(QPainter *painter, const QRect &rect, const Shift &shift, const Employee &employee);
    void drawCapacityIndicator(QPainter *painter, const QRect &rect, double capacity);
    void drawAlertIndicator(QPainter *painter, const QRect &rect, int alertLevel);
    QColor getEmployeeColor(const Employee &employee);
    QColor getCapacityColor(double capacity);

    // Capacity Analysis
    struct CapacityInfo {
        QString department;
        QString position;
        int required;
        int assigned;
        double percentage;
        int alertLevel; // 0=ok, 1=warning, 2=critical
    };

    QList<CapacityInfo> analyzeCapacity(const QDate &date);
    void showCapacityDetails(const QDate &date);

    // Alert Management
    struct Alert {
        QString id;
        QString type;
        QString message;
        int severity; // 0=info, 1=warning, 2=critical
        QDate date;
        QStringList affectedEmployees;
        QString recommendation;
    };

    QList<Alert> generateAlerts();
    void showAlert(const Alert &alert);

    // UI Components
    QVBoxLayout *m_mainLayout;
    QHBoxLayout *m_toolbarLayout;
    QSplitter *m_mainSplitter;

    // Toolbar
    QComboBox *m_viewModeCombo;
    QComboBox *m_displayModeCombo;
    QComboBox *m_employeeFilter;
    QComboBox *m_departmentFilter;
    QLineEdit *m_searchField;
    QPushButton *m_createShiftButton;
    QPushButton *m_capacityButton;
    QPushButton *m_exportButton;
    QPushButton *m_printButton;

    // Calendar Area
    QCalendarWidget *m_calendar;
    QLabel *m_dateLabel;
    QPushButton *m_prevButton;
    QPushButton *m_nextButton;
    QPushButton *m_todayButton;

    // Shift Grid
    QScrollArea *m_shiftScrollArea;
    QWidget *m_shiftGridWidget;
    QGridLayout *m_shiftGridLayout;
    QTableWidget *m_shiftTable;

    // Alert Panel
    QGroupBox *m_alertGroup;
    QVBoxLayout *m_alertLayout;
    QLabel *m_alertSummary;
    QPushButton *m_alertToggle;

    // Color Legend
    QGroupBox *m_legendGroup;
    QVBoxLayout *m_legendLayout;

    // State
    ViewMode m_viewMode;
    DisplayMode m_displayMode;
    QDate m_currentDate;
    QList<Employee> m_employees;
    QList<Shift> m_shifts;
    QList<VacationRequest> m_vacations;
    QList<Alert> m_alerts;

    // Professional styling
    QMap<QString, QColor> m_employeeColors;
    QMap<QString, QColor> m_departmentColors;

    // Time slots for detailed view
    QStringList m_timeSlots;
    int m_timeSlotHeight;
    int m_employeeColumnWidth;

    // Context menu
    QMenu *m_contextMenu;
    QMenu *m_shiftMenu;
    QMenu *m_employeeMenu;

    // Drag & Drop
    QString m_draggedShiftId;
    QString m_draggedEmployeeId;

    // Professional Features
    QTimer *m_refreshTimer;
    bool m_autoRefresh;
    int m_refreshInterval; // in seconds

    // Color management
    void initializeEmployeeColors();
    void generateDepartmentColors();
    QString getContrastColor(const QColor &backgroundColor);

    // Vacation conflict detection
    bool hasVacationConflict(const QString &employeeId, const QDate &date);
    QList<QString> getVacationConflicts(const QDate &date);

    // Professional layout calculations
    QSize calculateOptimalCellSize();
    int calculateTimeSlotCount();
    void optimizeLayout();
};

// Custom Widgets for Professional Look
class ShiftCell : public QFrame
{
    Q_OBJECT

public:
    explicit ShiftCell(const Shift &shift, const Employee &employee, QWidget *parent = nullptr);

    void setShift(const Shift &shift);
    void setEmployee(const Employee &employee);
    void setHighlighted(bool highlighted);
    void setAlertLevel(int level);

protected:
    void paintEvent(QPaintEvent *event) override;
    void mouseDoubleClickEvent(QMouseEvent *event) override;
    void mousePressEvent(QMouseEvent *event) override;
    void contextMenuEvent(QContextMenuEvent *event) override;

signals:
    void doubleClicked(const QString &shiftId);
    void contextMenuRequested(const QString &shiftId, const QPoint &position);

private:
    Shift m_shift;
    Employee m_employee;
    bool m_highlighted;
    int m_alertLevel;
    QColor m_backgroundColor;
    QColor m_textColor;
    QColor m_borderColor;
};

class CapacityIndicator : public QWidget
{
    Q_OBJECT

public:
    explicit CapacityIndicator(QWidget *parent = nullptr);

    void setCapacity(double percentage);
    void setRequired(int required);
    void setAssigned(int assigned);
    void setAlertLevel(int level);

protected:
    void paintEvent(QPaintEvent *event) override;

private:
    double m_percentage;
    int m_required;
    int m_assigned;
    int m_alertLevel;
};

#endif // SHIFTPLANNINGWIDGET_H