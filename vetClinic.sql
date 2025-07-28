CREATE TABLE Owner (
    ID_Owner INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    Surname VARCHAR(20) NOT NULL,
    Name VARCHAR(20) NOT NULL,
    Middle_Name VARCHAR(20),
    Phone NUMERIC(11, 0) CHECK (Phone BETWEEN 70000000000 AND 89999999999),
	Address VARCHAR(40) NOT NULL,
	Email VARCHAR(30)
);

CREATE TABLE Patient (
    ID_Pet INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    Name VARCHAR(20) NOT NULL,
    View VARCHAR(20) NOT NULL,
    Species VARCHAR(20) NOT NULL,
    Year_Of_Birth DATE NOT NULL,
	Color VARCHAR(20) NOT NULL,
	ID_Owner INT,
	FOREIGN KEY (ID_Owner) REFERENCES Owner(ID_Owner) ON DELETE SET NULL
);

CREATE TABLE Veterinarian (
    ID_Veterinarian INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    Surname VARCHAR(20) NOT NULL,
    Name VARCHAR(20) NOT NULL,
    Middle_Name VARCHAR(20) NOT NULL,
    Specialization VARCHAR(30) NOT NULL,
	Qualification VARCHAR(30) NOT NULL,
	Start_Time_Day TIME NOT NULL,
	End_Time_Day TIME NOT NULL
);

CREATE TABLE Service (
    ID_Service INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    Name VARCHAR(30) NOT NULL,
    Description VARCHAR(255) NOT NULL,
    Cost NUMERIC(7,2) NOT NULL
);

CREATE TABLE Appointment (
    ID_Appointment INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    Date DATE NOT NULL,
    Start_Time_Appointment TIME NOT NULL,
    End_Time_Appointment TIME NOT NULL,
    ID_Veterinarian INT,
	ID_Service INT,
	FOREIGN KEY (ID_Veterinarian) REFERENCES Veterinarian(ID_Veterinarian) ON DELETE SET NULL,
	FOREIGN KEY (ID_Service) REFERENCES Service(ID_Service) ON DELETE SET NULL
);

CREATE TABLE Questionnaire (
    ID_Questionnaire INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    Symptoms TEXT NOT NULL,
    Appointment_And_Treatment TEXT NOT NULL,
    ID_Pet INT,
    ID_Appointment INT,
	FOREIGN KEY (ID_Pet) REFERENCES Patient(ID_Pet) ON DELETE SET NULL,
	FOREIGN KEY (ID_Appointment) REFERENCES Appointment(ID_Appointment) ON DELETE SET NULL
);

CREATE TABLE user_cooperator (
  user_id SERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,--логин пользователя не должен повторяться
  password VARCHAR(100) NOT NULL
);

INSERT INTO user_cooperator (username, password)
VALUES 
  ('user1', '1234'),
  ('user2', '1111'),
  ('user3', '0000'),
  ('user4', 'password123'),
  ('user5', 'qwerty'),
  ('user6', 'admin123'),
  ('user7', 'mypassword'),
  ('user8', 'secretpass'),
  ('user9', 'letmein'),
  ('user10', 'welcome1'),
  ('user11', 'user123'),
  ('user12', 'test123'),
  ('user13', 'abc123'),
  ('user14', 'iloveyou'),
  ('user15', 'password1');


--Представление 1. Сколько было пациентов в промежутке(7 последних дней) принято у каждого ветеринара
CREATE VIEW Veterinarian_Patient_Count AS
SELECT v.Surname AS Veterinarian_Surname, v.Name AS Veterinarian_Name, COUNT(DISTINCT q.ID_Pet) AS Patient_Count
FROM Veterinarian v
JOIN Appointment a ON v.ID_Veterinarian = a.ID_Veterinarian
JOIN Questionnaire q ON a.ID_Appointment = q.ID_Appointment
WHERE a.Date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY v.Surname, v.Name;

SELECT Veterinarian_Surname, Veterinarian_Name, Patient_Count
FROM Veterinarian_Patient_Count;

--Представление 2. Вывод чека
CREATE VIEW Invoice_Check AS
SELECT
    'ЧЕК № ' || a.ID_Appointment AS Check_Number,
    'Дата: ' || a.Date AS Check_Date,
    'Ветеринар: ' || v.Surname || ' ' || v.Name || ' ' || v.Middle_Name AS Veterinarian_Name,
    'Пациент: ' || p.Name || ' (вид: ' || p.View || ', порода: ' || p.Species || ')' AS Pet_Info,
    'Услуга: ' || s.Name AS Service_Name,
    'Описание: ' || s.Description AS Service_Description,
    'Стоимость: ' || TO_CHAR(s.Cost, '99999.99') || ' руб.' AS Service_Cost
FROM Appointment a
JOIN Service s ON a.ID_Service = s.ID_Service
JOIN Veterinarian v ON a.ID_Veterinarian = v.ID_Veterinarian
JOIN Questionnaire q ON a.ID_Appointment = q.ID_Appointment
JOIN Patient p ON q.ID_Pet = p.ID_Pet;

SELECT Check_Number, Check_Date, Veterinarian_Name, Pet_Info, Service_Name, Service_Description, Service_Cost 
FROM Invoice_Check;

--Представление 3. Вывод карты пациента
CREATE VIEW Patient_Card AS
SELECT
    p.Name AS Pet_Name,
    p.View AS Pet_View,
    p.Species AS Pet_Species,
    p.Color AS Pet_Color,
    p.Year_Of_Birth AS Pet_Year_Of_Birth,
    o.Surname || ' ' || o.Name || ' ' || o.Middle_Name AS Owner_Name,
    o.Phone AS Owner_Phone,
    o.Address AS Owner_Address,
    o.Email AS Owner_Email,
    STRING_AGG(TO_CHAR(a.Date, 'YYYY-MM-DD') || ': ' || s.Name || ' (' || s.Cost || ' руб.)', '; ') AS Services,
    STRING_AGG(TO_CHAR(a.Date, 'YYYY-MM-DD') || ': ' || q.Symptoms, '; ') AS Symptoms,
    STRING_AGG(TO_CHAR(a.Date, 'YYYY-MM-DD') || ': ' || q.Appointment_And_Treatment, '; ') AS Treatment_Details
FROM Patient p
JOIN Questionnaire q ON p.ID_Pet = q.ID_Pet
JOIN Appointment a ON q.ID_Appointment = a.ID_Appointment
JOIN Service s ON a.ID_Service = s.ID_Service
JOIN Veterinarian v ON a.ID_Veterinarian = v.ID_Veterinarian
JOIN Owner o ON p.ID_Owner = o.ID_Owner
GROUP BY p.ID_Pet, o.ID_Owner;

SELECT Pet_Name, Pet_View, Pet_Species, Pet_Color, Pet_Year_Of_Birth, Owner_Name, Owner_Phone, Owner_Address, Owner_Email, Services, Symptoms, Treatment_Details
FROM Patient_Card;

--Представление 4. Список владельцев и их питомцев.
CREATE VIEW Owner_Pet_List AS
SELECT 
    CONCAT('Владелец: ', o.Surname, ' ', o.Name, ' ', COALESCE(o.Middle_Name, ''), 
           ', Телефон: ', o.Phone, ', Адрес: ', o.Address, 
           ', Email: ', COALESCE(o.Email, 'не указан')) AS Owner_Info,
    CONCAT('Питомец: ', p.Name, ' (', p.Species, ', ', p.View, '), Цвет: ', p.Color, 
           ', Дата рождения: ', p.Year_Of_Birth) AS Pet_Info
FROM Owner o
JOIN Patient p ON o.ID_Owner = p.ID_Owner;

SELECT Owner_Info, Pet_Info
FROM Owner_Pet_List;


---------------------------------------------------------------------------------------------------------------------------------------------------------------
--Процедура 1. Процедура для добавления нового владельца.(проверка есть ли уже)
CREATE OR REPLACE PROCEDURE Add_New_Owner(
    IN p_Surname VARCHAR(20),
    IN p_Name VARCHAR(20),
    IN p_Middle_Name VARCHAR(20),
    IN p_Phone NUMERIC(11, 0),
    IN p_Address VARCHAR(40),
    IN p_Email VARCHAR(30)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM Owner WHERE Surname = p_Surname AND Name = p_Name AND Phone = p_Phone) THEN
        RAISE NOTICE 'Владелец с таким номером телефона, фамилией и именем уже существует.';
    ELSE
        INSERT INTO Owner (Surname, Name, Middle_Name, Phone, Address, Email)
        VALUES (p_Surname, p_Name, p_Middle_Name, p_Phone, p_Address, p_Email);
        RAISE NOTICE 'Новый владелец добавлен успешно.';
    END IF;
END;
$$;

CALL Add_New_Owner('Иванов', 'Иван', 'Иванович', 89991234567, 'ул. Ленина, 15', 'ivanov@mail.com');

--Процедура 2.Процедура для определения возраста питомца
CREATE OR REPLACE PROCEDURE Get_Pet_Age_By_Name_And_Owner(
    IN p_Pet_Name VARCHAR(20),
    IN p_Owner_Surname VARCHAR(20),
    IN p_Owner_Name VARCHAR(20),
    IN p_Owner_Middle_Name VARCHAR(20),
    OUT pet_age INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    pet_birth_date DATE;
BEGIN
    SELECT p.Year_Of_Birth INTO pet_birth_date
    FROM Patient p
    JOIN Owner o ON p.ID_Owner = o.ID_Owner
    WHERE p.Name = p_Pet_Name
      AND o.Surname = p_Owner_Surname
      AND o.Name = p_Owner_Name
      AND o.Middle_Name = p_Owner_Middle_Name
    LIMIT 1;
    IF pet_birth_date IS NOT NULL THEN
        pet_age := EXTRACT(YEAR FROM AGE(pet_birth_date));
    ELSE
        pet_age := NULL;
    END IF;
END;
$$;


CALL Get_Pet_Age_By_Name_And_Owner('Барсик', 'Иванов', 'Алексей', 'Петрович', null);

--Процедура 3. Процедура для добавления записи
CREATE OR REPLACE PROCEDURE AddAppointment(
    IN vet_surname VARCHAR(20),
    IN vet_name VARCHAR(20),
    IN service_name VARCHAR(30),
    IN app_date DATE,
    IN start_time TIME,
    IN end_time TIME
)
LANGUAGE plpgsql
AS $$
DECLARE
    vet_id INT;
    service_id INT;
BEGIN

    SELECT ID_Veterinarian INTO vet_id
    FROM Veterinarian
    WHERE Surname = vet_surname AND Name = vet_name;
    IF vet_id IS NULL THEN
        RAISE EXCEPTION 'Врач с указанными именем и фамилией не найден';
    END IF;
    SELECT ID_Service INTO service_id
    FROM Service
    WHERE Name = service_name;
    IF service_id IS NULL THEN
        RAISE EXCEPTION 'Услуга с указанным названием не найдена';
    END IF;
    INSERT INTO Appointment (Date, Start_Time_Appointment, End_Time_Appointment, ID_Veterinarian, ID_Service)
    VALUES (app_date, start_time, end_time, vet_id, service_id);

    RAISE NOTICE 'Запись успешно добавлена: врач %, услуга %, дата %', vet_name, service_name, app_date;
END;
$$;

CALL AddAppointment(
    'Петров',
    'Андрей',
    'Общий осмотр',
    '2024-12-20',
    '10:00',
    '10:30'
);

--Процедура 4. Изменение времени записи
CREATE OR REPLACE PROCEDURE UpdateAppointmentTime(
    IN app_date DATE,
    IN current_start_time TIME,
    IN new_start_time TIME,
    IN new_end_time TIME,
    IN vet_surname VARCHAR(20),
    IN vet_name VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
DECLARE
    vet_id INT;
    appointment_id INT;
BEGIN
    SELECT ID_Veterinarian INTO vet_id
    FROM Veterinarian
    WHERE Surname = vet_surname AND Name = vet_name;
    IF vet_id IS NULL THEN
        RAISE EXCEPTION 'Врач с именем % % не найден', vet_name, vet_surname;
    END IF;
    SELECT ID_Appointment INTO appointment_id
    FROM Appointment
    WHERE Date = app_date 
      AND ID_Veterinarian = vet_id
      AND Start_Time_Appointment = current_start_time;
    IF appointment_id IS NULL THEN
        RAISE EXCEPTION 'Запись на дату %, врача % % и текущее время начала % не найдена', 
            app_date, vet_name, vet_surname, current_start_time;
    END IF;
    UPDATE Appointment
    SET Start_Time_Appointment = new_start_time,
        End_Time_Appointment = new_end_time
    WHERE ID_Appointment = appointment_id;
    RAISE NOTICE 'Время записи успешно обновлено: дата %, врач % %, новое начало %, новое окончание %',
        app_date, vet_name, vet_surname, new_start_time, new_end_time;
END;
$$;

CALL UpdateAppointmentTime(
    '2024-12-20',        -- Дата записи
    '12:00',             -- Текущее время начала записи
    '11:00',             -- Новое время начала записи
    '11:30',             -- Новое время окончания записи
    'Петров',            -- Фамилия врача
    'Андрей'             -- Имя врача
);

--Процедура 5. Удаление времени записи
CREATE OR REPLACE PROCEDURE DeleteAppointmentTime(
    IN app_date DATE,
    IN start_time TIME,
    IN vet_surname VARCHAR(20),
    IN vet_name VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
DECLARE
    vet_id INT;
    appointment_id INT;
BEGIN
    SELECT ID_Veterinarian INTO vet_id
    FROM Veterinarian
    WHERE Surname = vet_surname AND Name = vet_name;
    IF vet_id IS NULL THEN
        RAISE EXCEPTION 'Врач с именем % % не найден', vet_name, vet_surname;
    END IF;
    SELECT ID_Appointment INTO appointment_id
    FROM Appointment
    WHERE Date = app_date 
      AND Start_Time_Appointment = start_time
      AND ID_Veterinarian = vet_id;
    IF appointment_id IS NULL THEN
        RAISE EXCEPTION 'Запись на дату %, время % и врача % % не найдена', 
            app_date, start_time, vet_name, vet_surname;
    END IF;
    DELETE FROM Appointment
    WHERE ID_Appointment = appointment_id;
    RAISE NOTICE 'Запись на дату %, время % врача % % успешно удалена',
        app_date, start_time, vet_name, vet_surname;
END;
$$;

CALL DeleteAppointmentTime(
    '2024-12-20',        -- Дата записи
    '11:30',             -- Время начала записи
    'Петров',            -- Фамилия врача
    'Андрей'             -- Имя врача
);
SELECT AddAppointment('Петров', 'Андрей', 'Общий осмотр', '2024-12-20', '10:00', '10:30');

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Функция 1. Возвращает стоимость услуги по её названию.
CREATE OR REPLACE FUNCTION Get_Service_Cost(service_name VARCHAR)
RETURNS NUMERIC(7,2)
LANGUAGE plpgsql
AS $$
DECLARE
    service_cost NUMERIC(7,2);
BEGIN
    SELECT s.Cost INTO service_cost
    FROM Service s
    WHERE s.Name = service_name
    LIMIT 1;
    IF service_cost IS NULL THEN
        RAISE NOTICE 'Услуга с названием "%" не найдена.', service_name;
        RETURN NULL;
    ELSE
        RAISE NOTICE 'Услуга "%", стоимость: %.2f', service_name, service_cost;
        RETURN service_cost;
    END IF;
END;
$$;


SELECT Get_Service_Cost('Вакцинация');

--Функция 2. Возвращает расписание приёмов конкретного ветеринара.
CREATE OR REPLACE FUNCTION Get_Veterinarian_Schedule(vet_name VARCHAR, vet_surname VARCHAR)
RETURNS TABLE(Date DATE, Start_Time TIME, End_Time TIME, Service_Name VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT a.Date, a.Start_Time_Appointment, a.End_Time_Appointment, s.Name
    FROM Appointment a
    JOIN Veterinarian v ON a.ID_Veterinarian = v.ID_Veterinarian
    JOIN Service s ON a.ID_Service = s.ID_Service
    WHERE v.Name = vet_name
      AND v.Surname = vet_surname
    ORDER BY a.Date, a.Start_Time_Appointment;
END;
$$;

SELECT Date, Start_Time, End_Time, Service_Name
FROM Get_Veterinarian_Schedule('Андрей', 'Петров');

--Функция 3. Считает общую выручку за определённый период.
CREATE OR REPLACE FUNCTION Get_Total_Revenue(start_date DATE, end_date DATE)
RETURNS NUMERIC(10,2)
LANGUAGE plpgsql
AS $$
DECLARE
    total_revenue NUMERIC(10,2) := 0;
BEGIN
    SELECT SUM(s.Cost)
    INTO total_revenue
    FROM Appointment a
    JOIN Service s ON a.ID_Service = s.ID_Service
    WHERE a.Date BETWEEN start_date AND end_date;
    IF total_revenue IS NULL THEN
        total_revenue := 0;
    END IF;
    RETURN total_revenue;
END;
$$;

SELECT Get_Total_Revenue('2024-12-01', '2024-12-14');
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Триггер 1. Проверяет корректность временных значений при вставке новой записи в таблицу Appointment.
CREATE OR REPLACE FUNCTION check_appointment_insert()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Start_Time_Appointment >= NEW.End_Time_Appointment THEN
        RAISE EXCEPTION 'Время окончания должно быть больше времени начала';
    END IF;
    IF EXISTS (
        SELECT 1
        FROM Appointment a
        WHERE a.ID_Veterinarian = NEW.ID_Veterinarian
        AND a.Date = NEW.Date
        AND ((a.Start_Time_Appointment < NEW.End_Time_Appointment AND a.Start_Time_Appointment >= NEW.Start_Time_Appointment) 
             OR (a.End_Time_Appointment > NEW.Start_Time_Appointment AND a.End_Time_Appointment <= NEW.End_Time_Appointment))
    ) THEN
        RAISE EXCEPTION 'Время для выбранного ветеринара уже занято, выберите другое время';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER appointment_insert_trigger
BEFORE INSERT ON Appointment
FOR EACH ROW
EXECUTE FUNCTION check_appointment_insert();

INSERT INTO Appointment (ID_Veterinarian, Date, Start_Time_Appointment, End_Time_Appointment)
VALUES (1, '2024-12-14', '12:00:00', '12:30:00');


--Триггер 2. Аналогичная проверка для обновляемых записей в таблице Appointment.
CREATE OR REPLACE FUNCTION check_appointment_update()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Start_Time_Appointment >= NEW.End_Time_Appointment THEN
        RAISE EXCEPTION 'Время окончания должно быть больше времени начала';
    END IF;
    IF EXISTS (
        SELECT 1
        FROM Appointment a
        WHERE a.ID_Veterinarian = NEW.ID_Veterinarian
        AND a.Date = NEW.Date
        AND ((a.Start_Time_Appointment < NEW.End_Time_Appointment AND a.Start_Time_Appointment >= NEW.Start_Time_Appointment) 
             OR (a.End_Time_Appointment > NEW.Start_Time_Appointment AND a.End_Time_Appointment <= NEW.End_Time_Appointment))
        AND a.ID_Appointment != NEW.ID_Appointment
    ) THEN
        RAISE EXCEPTION 'Время для выбранного ветеринара уже занято, выберите другое время';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER appointment_update_trigger
BEFORE UPDATE ON Appointment
FOR EACH ROW
EXECUTE FUNCTION check_appointment_update();

UPDATE Appointment
SET Start_Time_Appointment = '11:20:00', End_Time_Appointment = '11:50:00'
WHERE ID_Appointment = 5;


--Триггер 3. Запись удалённых записей в таблицу Deleted_Appointments для истории.
-- Создание таблицы для истории удалённых записей
CREATE TABLE Deleted_Appointments (
    ID_Appointment INT,
    Date DATE,
    Start_Time_Appointment TIME,
    End_Time_Appointment TIME,
    ID_Veterinarian INT,
    ID_Service INT,
    Deleted_At TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION log_deleted_appointment()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO Deleted_Appointments (ID_Appointment, Date, Start_Time_Appointment, End_Time_Appointment, ID_Veterinarian, ID_Service)
    VALUES (OLD.ID_Appointment, OLD.Date, OLD.Start_Time_Appointment, OLD.End_Time_Appointment, OLD.ID_Veterinarian, OLD.ID_Service);

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER appointment_delete_trigger
AFTER DELETE ON Appointment
FOR EACH ROW
EXECUTE FUNCTION log_deleted_appointment();

DELETE FROM Appointment
WHERE ID_Appointment = 3;

--Триггер 4. 
-- Представление для отображения записи на приём с возможностью вставки
CREATE VIEW Appointment_View AS
SELECT 
    a.ID_Appointment,
    a.Date,
    a.Start_Time_Appointment,
    a.End_Time_Appointment,
    v.Surname AS vet_surname,
    v.Name AS vet_name,
    s.Name AS service_name
FROM Appointment a
JOIN Veterinarian v ON a.ID_Veterinarian = v.ID_Veterinarian
JOIN Service s ON a.ID_Service = s.ID_Service;

CREATE OR REPLACE FUNCTION instead_of_insert_block_weekend_appointments()
RETURNS TRIGGER AS $$
BEGIN
    IF EXTRACT(DOW FROM NEW.Date) IN (0, 6) THEN
        RAISE EXCEPTION 'Запрещено записываться на приём в выходные дни (субботу и воскресенье)';
    END IF;
    DECLARE
        vet_id INT;
        service_id INT;
    BEGIN
        SELECT ID_Veterinarian INTO vet_id
        FROM Veterinarian
        WHERE Surname = NEW.vet_surname AND Name = NEW.vet_name;
        SELECT ID_Service INTO service_id
        FROM Service
        WHERE Name = NEW.service_name;
        INSERT INTO Appointment (Date, Start_Time_Appointment, End_Time_Appointment, ID_Veterinarian, ID_Service)
        VALUES (NEW.Date, NEW.Start_Time_Appointment, NEW.End_Time_Appointment, vet_id, service_id);
        RETURN NULL;
    END;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER appointment_view_insert_block_weekend_appointments_trigger
INSTEAD OF INSERT ON Appointment_View
FOR EACH ROW
EXECUTE FUNCTION instead_of_insert_block_weekend_appointments();

-------------------------------------------------------------------------------------------------------------------
INSERT INTO Owner (Surname, Name, Middle_Name, Phone, Address, Email) VALUES
('Иванов', 'Петр', 'Александрович', 70012345678, 'Москва, ул. Ленина, д. 10', 'ivanov@mail.ru'),
('Петров', 'Сергей', 'Иванович', 70123456789, 'Санкт-Петербург, ул. Пушкина, д. 15', 'petrov@mail.ru'),
('Сидоров', 'Алексей', 'Владимирович', 70234567890, 'Казань, ул. Куйбышева, д. 25', 'sidorov@mail.ru'),
('Михайлов', 'Олег', 'Юрьевич', 70345678901, 'Волгоград, ул. Гагарина, д. 30', 'mikhailov@mail.ru'),
('Григорьев', 'Николай', 'Петрович', 70456789012, 'Ростов-на-Дону, ул. Пушкина, д. 40', 'grigoryev@mail.ru'),
('Новиков', 'Максим', 'Анатольевич', 70567890123, 'Екатеринбург, ул. Победы, д. 50', 'novikov@mail.ru'),
('Егорова', 'Мария', 'Сергеевна', 70678901234, 'Челябинск, ул. Толбухина, д. 60', 'egorova@mail.ru'),
('Дмитриев', 'Роман', 'Викторович', 70789012345, 'Тюмень, ул. Ленина, д. 70', 'dmitriev@mail.ru'),
('Шарова', 'Елена', 'Андреевна', 70890123456, 'Уфа, ул. Чернышевского, д. 80', 'sharova@mail.ru'),
('Федорова', 'Татьяна', 'Геннадьевна', 70901234567, 'Пермь, ул. Ленинградская, д. 90', 'fedorova@mail.ru'),
('Рябова', 'Анна', 'Олеговна', 71012345678, 'Краснодар, ул. Октябрьская, д. 100', 'ryabova@mail.ru'),
('Васильев', 'Денис', 'Павлович', 71123456789, 'Самара, ул. Димитрова, д. 110', 'vasiliev@mail.ru'),
('Смирнов', 'Вадим', 'Аркадьевич', 71234567890, 'Барнаул, ул. 50 лет Октября, д. 120', 'smirnov@mail.ru'),
('Попова', 'Ирина', 'Викторовна', 71345678901, 'Томск, ул. Карла Маркса, д. 130', 'popova@mail.ru'),
('Захарова', 'Светлана', 'Станиславовна', 71456789012, 'Красноярск, ул. Кирова, д. 140', 'zaharova@mail.ru');

INSERT INTO Patient (Name, View, Species, Year_Of_Birth, Color, ID_Owner) VALUES
('Барсик', 'Кот', 'Кошка', '2020-06-15', 'Серый', 1),
('Рекс', 'Собака', 'Пес', '2018-03-22', 'Черный', 2),
('Мурка', 'Кошка', 'Кошка', '2019-08-01', 'Белый', 3),
('Бобик', 'Собака', 'Пес', '2017-12-05', 'Коричневый', 4),
('Тимка', 'Кот', 'Кошка', '2022-11-12', 'Черный', 5),
('Шарик', 'Собака', 'Пес', '2016-09-19', 'Белый', 6),
('Грета', 'Собака', 'Пес', '2020-01-30', 'Серый', 7),
('Пушистик', 'Кошка', 'Кошка', '2021-03-10', 'Палевый', 8),
('Чарли', 'Собака', 'Пес', '2019-07-18', 'Черно-белый', 9),
('Мурка', 'Кошка', 'Кошка', '2015-12-25', 'Серый', 10),
('Ласка', 'Кошка', 'Кошка', '2021-05-13', 'Черный', 11),
('Мишка', 'Собака', 'Пес', '2016-11-20', 'Серый', 12),
('Федя', 'Кот', 'Кошка', '2020-02-25', 'Красный', 13),
('Джек', 'Собака', 'Пес', '2018-06-10', 'Черный', 14),
('Кеша', 'Птица', 'Попугай', '2022-04-05', 'Зеленый', 15);

INSERT INTO Veterinarian (Surname, Name, Middle_Name, Specialization, Qualification, Start_Time_Day, End_Time_Day) VALUES
('Иванов', 'Дмитрий', 'Юрьевич', 'Хирург', 'Ветеринарный врач', '09:00:00', '18:00:00'),
('Петрова', 'Елена', 'Анатольевна', 'Терапевт', 'Доктор ветеринарных наук', '09:00:00', '18:00:00'),
('Смирнов', 'Никита', 'Владимирович', 'Гастроэнтеролог', 'Кандидат ветеринарных наук', '10:00:00', '19:00:00'),
('Михайлов', 'Иван', 'Геннадьевич', 'Кардиолог', 'Ветеринарный врач', '08:00:00', '17:00:00'),
('Григорьева', 'Марина', 'Петровна', 'Дерматолог', 'Кандидат ветеринарных наук', '09:30:00', '18:00:00'),
('Лебедев', 'Анатолий', 'Сергеевич', 'Офтальмолог', 'Ассистент ветеринарного врача', '08:00:00', '17:00:00'),
('Сидорова', 'Юлия', 'Вячеславовна', 'Невролог', 'Ветеринарный врач', '10:00:00', '19:00:00'),
('Кузнецова', 'Ирина', 'Александровна', 'Онколог', 'Доктор ветеринарных наук', '08:30:00', '17:30:00'),
('Дмитриев', 'Алексей', 'Максимович', 'Стоматолог', 'Ветеринарный врач', '09:00:00', '18:00:00'),
('Новиков', 'Олег', 'Геннадьевич', 'Анестезиолог', 'Кандидат ветеринарных наук', '10:00:00', '19:00:00'),
('Лазарева', 'Маргарита', 'Петровна', 'Диетолог', 'Доктор ветеринарных наук', '09:00:00', '18:00:00'),
('Федоров', 'Михаил', 'Игоревич', 'Паразитолог', 'Ассистент ветеринарного врача', '08:30:00', '17:30:00'),
('Соколова', 'Татьяна', 'Владимировна', 'Эндокринолог', 'Кандидат ветеринарных наук', '09:00:00', '18:00:00'),
('Яковлева', 'Екатерина', 'Станиславовна', 'УЗИ и радиология', 'Ветеринарный врач', '08:00:00', '17:00:00'),
('Чернова', 'Алёна', 'Геннадьевна', 'Лабораторная диагностика', 'Кандидат ветеринарных наук', '09:00:00', '18:00:00');

INSERT INTO Service (Name, Description, Cost) VALUES
('Ветеринарная консультация', 'Консультация по общим вопросам здоровья питомца', 1000.00),
('Лечение травм', 'Обработка и лечение травм животных', 4500.00),
('Тестирование на инфекции', 'Диагностика инфекционных заболеваний', 1800.00),
('Эндоскопия', 'Осмотр внутренних органов с помощью эндоскопа', 3500.00),
('Лечение простуды', 'Лечение респираторных заболеваний и простуды', 1200.00),
('Вакцинация от чумки', 'Прививка против вируса чумки собак и кошек', 1300.00),
('Хирургическая кастрация', 'Операция по кастрации животных', 5000.00),
('Гигиеническая стрижка', 'Стрижка шерсти животных и уход за кожей', 1200.00),
('Обработка от блох и клещей', 'Обработка животных от внешних паразитов', 600.00),
('Уход за когтями', 'Обрезка когтей у домашних животных', 700.00),
('Физиотерапия для животных', 'Процедуры физиотерапевтического лечения', 2000.00),
('Лечение глазных заболеваний', 'Диагностика и лечение заболеваний глаз', 1500.00),
('Лечение ожогов', 'Терапия и уход за ожогами животных', 2500.00),
('Плановое обследование', 'Профилактическое обследование здоровья животного', 1500.00),
('Психологическая помощь', 'Коррекция поведения и стресса у питомцев', 1800.00);

INSERT INTO Appointment (Date, Start_Time_Appointment, End_Time_Appointment, ID_Veterinarian, ID_Service) VALUES
('2024-12-11', '09:00', '09:30', 1, 1),
('2024-12-11', '09:30', '10:00', 2, 2),
('2024-12-11', '10:00', '10:30', 3, 3),
('2024-12-11', '10:30', '11:00', 4, 4),
('2024-12-11', '11:00', '11:30', 5, 5),
('2024-12-11', '11:30', '12:00', 6, 6),
('2024-12-11', '12:00', '12:30', 7, 7),
('2024-12-11', '12:30', '13:00', 8, 8),
('2024-12-11', '13:00', '13:30', 9, 9),
('2024-12-11', '13:30', '14:00', 10, 10),
('2024-12-11', '14:00', '14:30', 11, 11),
('2024-12-11', '14:30', '15:00', 12, 12),
('2024-12-11', '15:00', '15:30', 13, 13),
('2024-12-11', '15:30', '16:00', 14, 14),
('2024-12-11', '16:00', '16:30', 15, 15),

('2024-12-12', '09:00', '09:30', 3, 3),
('2024-12-12', '09:30', '10:00', 3, 3),
('2024-12-12', '10:30', '11:00', 3, 3),
('2024-12-12', '11:00', '11:30', 3, 3),
('2024-12-12', '11:30', '12:00', 3, 3),
('2024-12-12', '12:00', '12:30', 3, 3),
('2024-12-12', '12:30', '13:00', 3, 3),
('2024-12-12', '13:00', '13:30', 3, 3),
('2024-12-12', '13:30', '14:00', 3, 3),
('2024-12-12', '14:00', '14:30', 3, 3),
('2024-12-12', '14:30', '15:00', 3, 3),
('2024-12-12', '15:00', '15:30', 3, 3),
('2024-12-12', '15:30', '16:00', 3, 3),
('2024-12-12', '16:00', '16:30', 3, 3),

('2024-12-13', '09:00', '09:30', 3, 3),
('2024-12-13', '09:30', '10:00', 3, 3),
('2024-12-13', '10:00', '10:30', 3, 3),
('2024-12-13', '10:30', '11:00', 3, 3),
('2024-12-13', '11:00', '11:30', 3, 3),
('2024-12-13', '11:30', '12:00', 3, 3),
('2024-12-13', '12:00', '12:30', 3, 3),
('2024-12-13', '12:30', '13:00', 3, 3),
('2024-12-13', '13:00', '13:30', 3, 3),
('2024-12-13', '13:30', '14:00', 3, 3),
('2024-12-13', '14:00', '14:30', 3, 3),
('2024-12-13', '14:30', '15:00', 3, 3),
('2024-12-13', '15:00', '15:30', 3, 3),
('2024-12-13', '15:30', '16:00', 3, 3),
('2024-12-13', '16:00', '16:30', 3, 3);


INSERT INTO Questionnaire (Symptoms, Appointment_And_Treatment, ID_Pet, ID_Appointment) VALUES
('Кашель, слезотечение', 'Прописан препарат для лечения кашля и глазных капель.', 1, 1),
('Отсутствие аппетита, вялость', 'Рекомендовано лечение с витаминами, назначено обследование.', 2, 2),
('Судороги, рвота', 'Назначено медикаментозное лечение, анализы для диагностики.', 3, 3),
('Трудности с дыханием', 'Применены ингаляторы и препараты для облегчения дыхания.', 4, 4),
('Проблемы с зубами', 'Назначен осмотр у стоматолога для диагностики состояния зубов.', 5, 5),
('Отказ от пищи, понос', 'Рекомендовано исключить определённые продукты из рациона, лечение диетой.', 6, 6),
('Проблемы с кожей', 'Назначены мази и препараты для восстановления кожи.', 7, 7),
('Обезвоживание, слабость', 'Лечение с введением жидкости внутривенно.', 8, 8),
('Болезненные ощущения в животе', 'Рекомендовано лечение с препаратами для улучшения пищеварения.', 9, 9),
('Высокая температура, слабость', 'Назначен курс антибактериальной терапии и противовирусных препаратов.', 10, 10),
('Сухость в глазах, боли в глазах', 'Назначены глазные капли и лекарства для улучшения состояния глаз.', 11, 11),
('Отечность, повышение температуры', 'Назначены антигистаминные препараты и медикаменты для устранения воспаления.', 12, 12),
('Проблемы с ушей', 'Рекомендовано лечение с применением ушных капель и антибиотиков.', 13, 13),
('Проблемы с суставами', 'Назначен курс физиотерапии для восстановления функций суставов.', 14, 14),
('Дерматологические заболевания', 'Прописаны мази и препараты для лечения кожных заболеваний.', 15, 15);