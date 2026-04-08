#ifndef WEBDAVMANAGER_H
#define WEBDAVMANAGER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QString>
#include <QJsonObject>
#include <QJsonDocument>
#include <QTimer>
#include <QMutex>

class WebDAVManager : public QObject
{
    Q_OBJECT

public:
    explicit WebDAVManager(QObject *parent = nullptr);
    ~WebDAVManager();

    // Konfiguration
    void setCredentials(const QString &username, const QString &password);
    void setServerUrl(const QString &url);
    void setBasePath(const QString &path);

    // Verbindungstest
    void testConnection();

    // Datei-Operationen
    void uploadFile(const QString &localPath, const QString &remotePath);
    void downloadFile(const QString &remotePath, const QString &localPath);
    void deleteFile(const QString &remotePath);
    void listDirectory(const QString &remotePath = "");

    // Eingliederungshilfe-spezifische Operationen
    void saveEmployees(const QJsonObject &employees);
    void loadEmployees();
    void saveClients(const QJsonObject &clients);
    void loadClients();
    void saveShifts(const QJsonObject &shifts);
    void loadShifts();
    void saveVacationRequests(const QJsonObject &vacations);
    void loadVacationRequests();

    // Backup & Sync
    void createBackup();
    void syncData();
    void setAutoSync(bool enabled, int intervalMinutes = 5);

    // Status
    bool isConnected() const { return m_connected; }
    QString lastError() const { return m_lastError; }

signals:
    void connectionStatusChanged(bool connected);
    void fileUploaded(const QString &remotePath);
    void fileDownloaded(const QString &localPath);
    void fileDeleted(const QString &remotePath);
    void directoryListed(const QStringList &files);
    void dataLoaded(const QString &dataType, const QJsonObject &data);
    void dataSaved(const QString &dataType);
    void syncCompleted();
    void syncFailed(const QString &error);
    void progressChanged(int percentage);
    void errorOccurred(const QString &error);

private slots:
    void onNetworkReplyFinished();
    void onAutoSyncTimer();

private:
    QNetworkAccessManager *m_networkManager;
    QString m_serverUrl;
    QString m_basePath;
    QString m_username;
    QString m_password;
    bool m_connected;
    QString m_lastError;
    QTimer *m_autoSyncTimer;
    QMutex m_mutex;

    // Hilfsfunktionen
    QNetworkRequest createRequest(const QString &path, const QString &method = "GET");
    QString createAuthHeader();
    void processWebDAVResponse(QNetworkReply *reply, const QString &operation);
    QString createPropFindXml();
    QJsonObject encryptData(const QJsonObject &data);
    QJsonObject decryptData(const QJsonObject &encryptedData);

    // Pfad-Hilfsfunktionen
    QString getEmployeesPath() const { return m_basePath + "/employees.json"; }
    QString getClientsPath() const { return m_basePath + "/clients.json"; }
    QString getShiftsPath() const { return m_basePath + "/shifts.json"; }
    QString getVacationsPath() const { return m_basePath + "/vacations.json"; }
    QString getBackupPath() const;

    // Pending Operations für Retry-Mechanismus
    struct PendingOperation {
        QString type;
        QString path;
        QJsonObject data;
        int retryCount;
    };
    QList<PendingOperation> m_pendingOperations;
    void retryFailedOperations();
};

#endif // WEBDAVMANAGER_H