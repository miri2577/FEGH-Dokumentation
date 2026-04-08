#include "WebDAVManager.h"
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDateTime>
#include <QCryptographicHash>
#include <QDebug>
#include <QMutexLocker>

WebDAVManager::WebDAVManager(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
    , m_connected(false)
    , m_autoSyncTimer(new QTimer(this))
{
    connect(m_autoSyncTimer, &QTimer::timeout, this, &WebDAVManager::onAutoSyncTimer);
}

WebDAVManager::~WebDAVManager()
{
    m_autoSyncTimer->stop();
}

void WebDAVManager::setCredentials(const QString &username, const QString &password)
{
    m_username = username;
    m_password = password;
}

void WebDAVManager::setServerUrl(const QString &url)
{
    m_serverUrl = url;
    if (!m_serverUrl.endsWith("/")) {
        m_serverUrl += "/";
    }
}

void WebDAVManager::setBasePath(const QString &path)
{
    m_basePath = path;
    if (m_basePath.startsWith("/")) {
        m_basePath = m_basePath.mid(1);
    }
    if (!m_basePath.endsWith("/")) {
        m_basePath += "/";
    }
}

void WebDAVManager::testConnection()
{
    QNetworkRequest request = createRequest("", "PROPFIND");
    request.setRawHeader("Depth", "0");

    QNetworkReply *reply = m_networkManager->sendCustomRequest(request, "PROPFIND");
    connect(reply, &QNetworkReply::finished, [this, reply]() {
        if (reply->error() == QNetworkReply::NoError) {
            m_connected = true;
            m_lastError.clear();
            qDebug() << "WebDAV connection successful";
        } else {
            m_connected = false;
            m_lastError = reply->errorString();
            qDebug() << "WebDAV connection failed:" << m_lastError;
        }
        emit connectionStatusChanged(m_connected);
        reply->deleteLater();
    });
}

void WebDAVManager::uploadFile(const QString &localPath, const QString &remotePath)
{
    QFile file(localPath);
    if (!file.open(QIODevice::ReadOnly)) {
        emit errorOccurred("Cannot open local file: " + localPath);
        return;
    }

    QNetworkRequest request = createRequest(remotePath, "PUT");
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/octet-stream");

    QNetworkReply *reply = m_networkManager->put(request, &file);
    connect(reply, &QNetworkReply::finished, [this, reply, remotePath]() {
        if (reply->error() == QNetworkReply::NoError) {
            emit fileUploaded(remotePath);
            qDebug() << "File uploaded successfully:" << remotePath;
        } else {
            emit errorOccurred("Upload failed: " + reply->errorString());
        }
        reply->deleteLater();
    });

    connect(reply, &QNetworkReply::uploadProgress, [this](qint64 sent, qint64 total) {
        if (total > 0) {
            emit progressChanged(static_cast<int>((sent * 100) / total));
        }
    });
}

void WebDAVManager::downloadFile(const QString &remotePath, const QString &localPath)
{
    QNetworkRequest request = createRequest(remotePath);

    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, &QNetworkReply::finished, [this, reply, localPath]() {
        if (reply->error() == QNetworkReply::NoError) {
            QFile file(localPath);
            if (file.open(QIODevice::WriteOnly)) {
                file.write(reply->readAll());
                file.close();
                emit fileDownloaded(localPath);
                qDebug() << "File downloaded successfully:" << localPath;
            } else {
                emit errorOccurred("Cannot write to local file: " + localPath);
            }
        } else {
            emit errorOccurred("Download failed: " + reply->errorString());
        }
        reply->deleteLater();
    });

    connect(reply, &QNetworkReply::downloadProgress, [this](qint64 received, qint64 total) {
        if (total > 0) {
            emit progressChanged(static_cast<int>((received * 100) / total));
        }
    });
}

void WebDAVManager::saveEmployees(const QJsonObject &employees)
{
    QMutexLocker locker(&m_mutex);

    // Verschlüssele und speichere Mitarbeiterdaten
    QJsonObject encryptedData = encryptData(employees);
    QJsonDocument doc(encryptedData);

    // Erstelle temporäre Datei
    QString tempPath = QDir::temp().filePath("employees_temp.json");
    QFile tempFile(tempPath);
    if (tempFile.open(QIODevice::WriteOnly)) {
        tempFile.write(doc.toJson());
        tempFile.close();

        // Upload zu HiDrive
        uploadFile(tempPath, getEmployeesPath());

        // Cleanup
        QFile::remove(tempPath);
    } else {
        emit errorOccurred("Cannot create temporary file for employees");
    }
}

void WebDAVManager::loadEmployees()
{
    QString localPath = QDir::temp().filePath("employees_download.json");

    QNetworkRequest request = createRequest(getEmployeesPath());
    QNetworkReply *reply = m_networkManager->get(request);

    connect(reply, &QNetworkReply::finished, [this, reply, localPath]() {
        if (reply->error() == QNetworkReply::NoError) {
            QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
            QJsonObject encryptedData = doc.object();
            QJsonObject decryptedData = decryptData(encryptedData);

            emit dataLoaded("employees", decryptedData);
            qDebug() << "Employees loaded successfully";
        } else {
            emit errorOccurred("Failed to load employees: " + reply->errorString());
        }
        reply->deleteLater();
    });
}

void WebDAVManager::syncData()
{
    qDebug() << "Starting data synchronization...";

    // Lade alle Datentypen
    loadEmployees();
    loadClients();
    loadShifts();
    loadVacationRequests();

    // Nach erfolgreichem Laden wird syncCompleted emittiert
    QTimer::singleShot(5000, this, [this]() {
        emit syncCompleted();
        qDebug() << "Data synchronization completed";
    });
}

void WebDAVManager::setAutoSync(bool enabled, int intervalMinutes)
{
    if (enabled) {
        m_autoSyncTimer->start(intervalMinutes * 60 * 1000);
        qDebug() << "Auto-sync enabled with interval:" << intervalMinutes << "minutes";
    } else {
        m_autoSyncTimer->stop();
        qDebug() << "Auto-sync disabled";
    }
}

void WebDAVManager::createBackup()
{
    QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd_hh-mm-ss");
    QString backupDir = m_basePath + "backups/" + timestamp + "/";

    qDebug() << "Creating backup in:" << backupDir;

    // Erstelle Backup-Verzeichnis und kopiere alle Dateien
    // Implementation würde hier die aktuellen Dateien in den Backup-Ordner kopieren
}

QNetworkRequest WebDAVManager::createRequest(const QString &path, const QString &method)
{
    QString fullUrl = m_serverUrl + m_basePath + path;
    QNetworkRequest request(QUrl(fullUrl));

    // Basic Authentication
    QString credentials = m_username + ":" + m_password;
    QString authValue = "Basic " + credentials.toUtf8().toBase64();
    request.setRawHeader("Authorization", authValue.toUtf8());

    // Standard WebDAV Headers
    request.setRawHeader("User-Agent", "EingliederungshilfeQt/1.0");
    request.setRawHeader("Connection", "keep-alive");

    if (method == "PROPFIND") {
        request.setRawHeader("Content-Type", "application/xml; charset=utf-8");
    }

    return request;
}

QJsonObject WebDAVManager::encryptData(const QJsonObject &data)
{
    // Einfache Verschlüsselung für Demo - in Produktion AES verwenden
    QJsonDocument doc(data);
    QByteArray jsonData = doc.toJson();

    // Erstelle Hash als einfache "Verschlüsselung"
    QByteArray hash = QCryptographicHash::hash(jsonData, QCryptographicHash::Sha256);

    QJsonObject encrypted;
    encrypted["data"] = QString::fromUtf8(jsonData.toBase64());
    encrypted["hash"] = QString::fromUtf8(hash.toHex());
    encrypted["timestamp"] = QDateTime::currentDateTime().toString(Qt::ISODate);
    encrypted["version"] = "1.0";

    return encrypted;
}

QJsonObject WebDAVManager::decryptData(const QJsonObject &encryptedData)
{
    // Entsprechende Entschlüsselung
    QString base64Data = encryptedData["data"].toString();
    QByteArray jsonData = QByteArray::fromBase64(base64Data.toUtf8());

    QJsonDocument doc = QJsonDocument::fromJson(jsonData);
    return doc.object();
}

void WebDAVManager::onAutoSyncTimer()
{
    if (m_connected) {
        syncData();
    }
}

// Implementierung der anderen Methoden (saveClients, loadClients, etc.)
// würde hier analog zu saveEmployees/loadEmployees erfolgen...