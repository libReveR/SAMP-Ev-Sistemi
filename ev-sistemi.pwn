// Ev Sistemi
// Script by ReveR (Batu)
// Bir Sıkıntı olursa discord 'benbatuya' yazabilirsiniz.

#include <a_samp>
#include <a_mysql>
#include <sscanf2>
#include <streamer>
#include <zcmd>

// MySQL bağlantı bilgileri
#define MYSQL_HOST   "localhost"
#define MYSQL_USER   "root"
#define MYSQL_PASS   ""
#define MYSQL_DB     "reverbatu"

// Global değişkenler
new MySQL:mySQL;

// Ev bilgileri yapısı
enum EvInfo {
    evID,
    evIsim[50],
    evFiyat,
    evX,
    evY,
    evZ,
    evOyuncuID,
    evBakimMasraflari,
    evDurum[20]
};

// Forwards
forward CheckPlayerBalance(int playerid, int amount);
forward UpdatePlayerBalance(int playerid, int amount);
forward BuyHouse(int playerid, int ev_id);
forward SellHouse(int playerid, int ev_id);
forward RentHouse(int playerid, int ev_id, int days);
forward UpdateHouseStatus(int ev_id, const status[]);

// Publics
public OnGameModeInit() {
    mySQL = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS, MYSQL_DB);
    if (!mySQL) {
        print("MySQL bağlantısı sağlanamadı.");
        return 0;
    }
    return 1;
}

public OnGameModeExit() {
    mysql_close(mySQL);
    return 1;
}

public CheckPlayerBalance(int playerid, int amount) {
    new balance;
    mysql_query("SELECT balance FROM players WHERE id = %d", GetPlayerID(playerid));
    mysql_store_result();
    
    if (mysql_num_rows() == 0) return false;
    mysql_fetch_row(balance);

    return (balance >= amount);
}

public UpdatePlayerBalance(int playerid, int amount) {
    mysql_query("UPDATE players SET balance = balance + %d WHERE id = %d", amount, GetPlayerID(playerid));
}

public BuyHouse(int playerid, int ev_id) {
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    
    mysql_query("SELECT id, isim, fiyat, x, y, z FROM evler WHERE id = %d AND oyuncu_id IS NULL", ev_id);
    mysql_store_result();
    
    if (mysql_num_rows() == 0) return false;
    
    new fiyat;
    mysql_fetch_row(ev_id, fiyat, x, y, z);
    
    if (!IsPlayerInRangeOfPoint(playerid, 10.0, x, y, z)) return false;
    
    if (!CheckPlayerBalance(playerid, fiyat)) return false;
    
    mysql_query("UPDATE evler SET oyuncu_id = %d WHERE id = %d", GetPlayerID(playerid), ev_id);
    UpdatePlayerBalance(playerid, -fiyat);
    
    return true;
}

public SellHouse(int playerid, int ev_id) {
    new fiyat;
    mysql_query("SELECT fiyat FROM evler WHERE id = %d AND oyuncu_id = %d", ev_id, GetPlayerID(playerid));
    mysql_store_result();
    
    if (mysql_num_rows() == 0) return false;
    
    mysql_fetch_row(fiyat);
    
    mysql_query("UPDATE evler SET oyuncu_id = NULL WHERE id = %d", ev_id);
    UpdatePlayerBalance(playerid, fiyat / 2);
    
    return true;
}

public RentHouse(int playerid, int ev_id, int days) {
    new fiyat;
    mysql_query("SELECT fiyat FROM evler WHERE id = %d AND oyuncu_id IS NULL", ev_id);
    mysql_store_result();
    
    if (mysql_num_rows() == 0) return false;
    
    mysql_fetch_row(fiyat);
    
    if (!CheckPlayerBalance(playerid, fiyat * days)) return false;
    
    mysql_query("UPDATE evler SET oyuncu_id = %d WHERE id = %d", GetPlayerID(playerid), ev_id);
    UpdatePlayerBalance(playerid, -fiyat * days);
    
    return true;
}

public UpdateHouseStatus(int ev_id, const status[]) {
    mysql_query("UPDATE evler SET durum = '%s' WHERE id = %d", status, ev_id);
}

// CMDS
CMD:evolustur(playerid, params[]) {
    new isim[50];
    new fiyat;
    
    if (sscanf(params, "si", isim, fiyat)) 
        return SendClientMessage(playerid, COLOR_RED, "Kullanım: /evolustur [isim] [fiyat]");
    
    if (fiyat <= 0) 
        return SendClientMessage(playerid, COLOR_RED, "Fiyat 0'dan büyük olmalıdır.");
    
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    
    mysql_query("INSERT INTO evler (isim, fiyat, x, y, z) VALUES ('%s', %d, %f, %f, %f)", isim, fiyat, x, y, z);
    
    SendClientMessage(playerid, COLOR_GREEN, "Ev başarıyla oluşturuldu.");
    return 1;
}

CMD:evsil(playerid, params[]) {
    new ev_id;
    
    if (sscanf(params, "i", ev_id)) 
        return SendClientMessage(playerid, COLOR_RED, "Kullanım: /evsil [ev id]");
    
    mysql_query("DELETE FROM evler WHERE id = %d", ev_id);
    
    SendClientMessage(playerid, COLOR_GREEN, "Ev başarıyla silindi.");
    return 1;
}

CMD:evduzenle(playerid, params[]) {
    new ev_id;
    
    if (sscanf(params, "i", ev_id)) 
        return SendClientMessage(playerid, COLOR_RED, "Kullanım: /evduzenle [ev id]");
    
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    
    mysql_query("UPDATE evler SET x = %f, y = %f, z = %f WHERE id = %d", x, y, z, ev_id);
    
    SendClientMessage(playerid, COLOR_GREEN, "Ev başarıyla düzenlendi.");
    return 1;
}

CMD:evmenu(playerid, params[]) {
    // Ev içi yönetim menüsü
    SendClientMessage(playerid, COLOR_YELLOW, "Ev menüsü burada olacak.");
    // Ek işlevsellik eklenebilir
    return 1;
}

CMD:evegit(playerid, params[]) {
    new oyuncu_id;
    
    mysql_query("SELECT x, y, z FROM evler WHERE oyuncu_id = %d", GetPlayerID(playerid));
    mysql_store_result();
    
    if (mysql_num_rows() == 0) 
        return SendClientMessage(playerid, COLOR_RED, "Ev bulamadım.");
    
    new Float:x, Float:y, Float:z;
    mysql_fetch_row(x, y, z);
    SetPlayerPos(playerid, x, y, z);
    
    SendClientMessage(playerid, COLOR_GREEN, "Evine ışınlandın.");
    return 1;
}

CMD:evgir(playerid, params[]) {
    // Ev içine girme işlemi
    SendClientMessage(playerid, COLOR_YELLOW, "Ev içine giriş sağlandı.");
    return 1;
}

CMD:evcik(playerid, params[]) {
    // Ev dışına çıkma işlemi
    SendClientMessage(playerid, COLOR_YELLOW, "Evden çıkış sağlandı.");
    return 1;
}

CMD:evsatinal(playerid, params[]) {
    new ev_id;
    
    if (sscanf(params, "i", ev_id)) 
        return SendClientMessage(playerid, COLOR_RED, "Kullanım: /evsatinal [ev id]");
    
    if (!BuyHouse(playerid, ev_id)) 
        return SendClientMessage(playerid, COLOR_RED, "Ev satın alınamadı.");
    
    SendClientMessage(playerid, COLOR_GREEN, "Ev başarıyla satın alındı.");
    return 1;
}

CMD:evsat(playerid, params[]) {
    new ev_id;
    
    if (sscanf(params, "i", ev_id)) 
        return SendClientMessage(playerid, COLOR_RED, "Kullanım: /evsat [ev id]");
    
    if (!SellHouse(playerid, ev_id)) 
        return SendClientMessage(playerid, COLOR_RED, "Ev satılamadı.");
    
    SendClientMessage(playerid, COLOR_GREEN, "Ev başarıyla satıldı.");
    return 1;
}

CMD:evkirala(playerid, params[]) {
    new ev_id, days;
    
    if (sscanf(params, "ii", ev_id, days)) 
        return SendClientMessage(playerid, COLOR_RED, "Kullanım: /evkirala [ev id] [gün sayısı]");
    
    if (days <= 0) 
        return SendClientMessage(playerid, COLOR_RED, "Gün sayısı 0'dan büyük olmalıdır.");
    
    if (!RentHouse(playerid, ev_id, days)) 
        return SendClientMessage(playerid, COLOR_RED, "Ev kiralanamadı.");
    
    SendClientMessage(playerid, COLOR_GREEN, "Ev başarıyla kiralandı.");
    return 1;
}

CMD:evbakim(playerid, params[]) {
    new ev_id;
    
    if (sscanf(params, "i", ev_id)) 
        return SendClientMessage(playerid, COLOR_RED, "Kullanım: /evbakim [ev id]");
    
    new bakim_masraflari = 5000; // Bakım masrafı örneği
    UpdatePlayerBalance(playerid, -bakim_masraflari);
    SendClientMessage(playerid, COLOR_GREEN, "Ev bakım masrafları ödendi.");
    
    return 1;
}

CMD:evdurum(playerid, params[]) {
    new ev_id;
    new durum[20];
    
    if (sscanf(params, "is", ev_id, durum)) 
        return SendClientMessage(playerid, COLOR_RED, "Kullanım: /evdurum [ev id] [durum]");
    
    UpdateHouseStatus(ev_id, durum);
    SendClientMessage(playerid, COLOR_GREEN, "Ev durumu başarıyla güncellendi.");
    return 1;
}
