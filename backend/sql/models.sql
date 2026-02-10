-- ============================================================================
-- CREATE ENUMS
-- ============================================================================


\echo '=========================================='
\echo '>>> STEP 1: Creating ENUM types...'
\echo '=========================================='

\echo '    [1/5] Creating user_role enum (Student, Lecturer, Administrator)...'
CREATE TYPE user_role AS ENUM ('Student', 'Lecturer', 'Administrator');


\echo '    ✓ user_role created'

\echo '    [2/5] Creating event_type enum (class, meeting, seminar)...'
CREATE TYPE event_type AS ENUM ('class', 'meeting', 'seminar');


\echo '    ✓ event_type created'

\echo '    [3/5] Creating event_status enum (scheduled, running, canceled, completed)...'
CREATE TYPE event_status AS ENUM ('scheduled', 'running', 'canceled', 'completed');


\echo '    ✓ event_status created'

\echo '    [4/5] Creating registration_status enum (pending, completed, withdrawn, no-show)...'
CREATE TYPE registration_status AS ENUM ('pending', 'completed', 'withdrawn', 'no-show');


\echo '    ✓ registration_status created'

\echo '    [5/5] Creating presence_status enum (present, absent, late)...'
CREATE TYPE presence_status AS ENUM ('present', 'absent', 'late');

\echo ' ✓ presence_status created' \echo ''

-- Departments


\echo '=========================================='
\echo '>>> STEP 2: Creating Tables...'
\echo '=========================================='

\echo '    [1/7] Creating department table...'
CREATE TABLE department (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        deleted_at TIMESTAMP
    WITH
        TIME ZONE
);

\echo ' ✓ department table created'

-- Roles
\echo '    [2/7] Creating role table...'
CREATE TABLE role (
    id BIGSERIAL PRIMARY KEY,
    name user_role NOT NULL UNIQUE,
    created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

\echo ' ✓ role table created'

-- Users
\echo '    [3/7] Creating user table...'
CREATE TABLE "user" (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    telephone VARCHAR(20),
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    department_id BIGINT NOT NULL REFERENCES department (id),
    role_id BIGINT NOT NULL REFERENCES role (id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        deleted_at TIMESTAMP
    WITH
        TIME ZONE
);

\echo ' ✓ user table created'

-- Courses
\echo '    [4/7] Creating course table...'
CREATE TABLE course (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    code VARCHAR(50) NOT NULL UNIQUE,
    department_id BIGINT NOT NULL REFERENCES department (id),
    created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        deleted_at TIMESTAMP
    WITH
        TIME ZONE
);

\echo ' ✓ course table created'

-- Events
\echo '    [5/7] Creating event table...'
CREATE TABLE event (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type event_type NOT NULL,
    status event_status DEFAULT 'scheduled',
    location VARCHAR(255),
    start_at TIMESTAMP
    WITH
        TIME ZONE NOT NULL,
        stop_at TIMESTAMP
    WITH
        TIME ZONE NOT NULL,
        organizer_id BIGINT NOT NULL REFERENCES "user" (id),
        course_id BIGINT NOT NULL REFERENCES course (id),
        created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        deleted_at TIMESTAMP
    WITH
        TIME ZONE,
        CONSTRAINT valid_duration CHECK (stop_at > start_at)
);

\echo ' ✓ event table created'

-- Registrations
\echo '    [6/7] Creating registration table...'
CREATE TABLE registration (
    id BIGSERIAL PRIMARY KEY,
    event_id BIGINT NOT NULL REFERENCES event (id),
    user_id BIGINT NOT NULL REFERENCES "user" (id),
    status registration_status DEFAULT 'pending',
    completed_at TIMESTAMP
    WITH
        TIME ZONE,
        created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (event_id, user_id),
        CONSTRAINT completed_logic CHECK (
            (
                status = 'completed'
                AND completed_at IS NOT NULL
            )
            OR (status != 'completed')
        )
);

\echo ' ✓ registration table created'

-- Presence (Attendance)
\echo '    [7/7] Creating presence table...'
CREATE TABLE presence (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES "user" (id),
    event_id BIGINT NOT NULL REFERENCES event (id),
    status presence_status DEFAULT 'present',
    scanned_at TIMESTAMP
    WITH
        TIME ZONE,
        created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        UNIQUE (user_id, event_id),
        CONSTRAINT scanned_logic CHECK (
            (status = 'absent' AND scanned_at IS NULL)
            OR (status IN ('present', 'late') AND scanned_at IS NOT NULL)
        )
);

\echo ' ✓ presence table created'

-- QR Codes
\echo '    [8/8] Creating qr_code table...'
CREATE TABLE qr_code (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(500) NOT NULL UNIQUE, -- Store as text (base64, URL-safe string)
    event_id BIGINT NOT NULL REFERENCES event (id) ON DELETE CASCADE,
    created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        expired_at TIMESTAMP
    WITH
        TIME ZONE NOT NULL
);

\echo ' ✓ qr_code table created' \echo ''

-- Indexes for performance


\echo '=========================================='
\echo '>>> STEP 3: Creating Indexes...'
\echo '=========================================='

\echo '    Creating 14 indexes for query performance...'
\echo '    ✓ idx_user_department'
CREATE INDEX idx_user_department ON "user" (department_id);

\echo '    ✓ idx_user_role'
CREATE INDEX idx_user_role ON "user" (role_id);

\echo '    ✓ idx_course_department'
CREATE INDEX idx_course_department ON course (department_id);

\echo '    ✓ idx_event_course'
CREATE INDEX idx_event_course ON event(course_id);

\echo '    ✓ idx_event_organizer'
CREATE INDEX idx_event_organizer ON event(organizer_id);

\echo '    ✓ idx_event_status'
CREATE INDEX idx_event_status ON event(status);

\echo '    ✓ idx_registration_event'
CREATE INDEX idx_registration_event ON registration (event_id);

\echo '    ✓ idx_registration_user'
CREATE INDEX idx_registration_user ON registration (user_id);

\echo '    ✓ idx_presence_event'
CREATE INDEX idx_presence_event ON presence (event_id);

\echo '    ✓ idx_presence_user'
CREATE INDEX idx_presence_user ON presence (user_id);

\echo '    ✓ idx_presence_scanned'
CREATE INDEX idx_presence_scanned ON presence (scanned_at);

\echo '    ✓ idx_qrcode_event'
CREATE INDEX idx_qrcode_event ON qr_code (event_id);

\echo '    ✓ idx_qrcode_expired'
CREATE INDEX idx_qrcode_expired ON qr_code (expired_at);

\echo ' All 14 indexes created successfully!' \echo ''

-- ============================================================================
-- TEST DATA
-- ============================================================================


\echo '=========================================='
\echo '>>> STEP 4: Loading Test Data...'
\echo '=========================================='

\echo '    [1/7] Inserting Roles (Student, Lecturer, Administrator)...'

-- Insert Roles
INSERT INTO
    role (name)
VALUES ('Student'),
    ('Lecturer'),
    ('Administrator');


\echo '    ✓ 3 roles inserted'

\echo '    [2/7] Inserting Departments (SE, NS, ISM)...'

-- Insert Departments
INSERT INTO
    department (code, name)
VALUES ('SE', 'Software Engineering'),
    (
        'NS',
        'Networking and Security'
    ),
    (
        'ISM',
        'Information Systems Management'
    );


\echo '    ✓ 3 departments inserted'

\echo '    [3/7] Inserting Lecturers (1 per department + Admin)...'

-- Insert Lecturers (1 per department + 1 administrator)
INSERT INTO
    "user" (
        name,
        telephone,
        email,
        password,
        department_id,
        role_id,
        is_active
    )
VALUES (
        'Dr. Emily Johnson',
        '+234-801-234-5001',
        'emily.johnson@university.edu',
        'hashed_password_1',
        1,
        2,
        TRUE
    ),
    (
        'Prof. Samuel Okafor',
        '+234-801-234-5002',
        'samuel.okafor@university.edu',
        'hashed_password_2',
        2,
        2,
        TRUE
    ),
    (
        'Dr. Patricia Adeyemi',
        '+234-801-234-5003',
        'patricia.adeyemi@university.edu',
        'hashed_password_3',
        3,
        2,
        TRUE
    ),
    (
        'Admin User',
        '+234-801-234-5000',
        'admin@university.edu',
        'hashed_password_admin',
        1,
        3,
        TRUE
    );


\echo '    ✓ 4 lecturers/admin inserted'

\echo '    [4/7] Inserting Courses (3 per department = 9 total)...'

-- ============================================================================
-- COURSES (3 per department)
-- ============================================================================

-- Software Engineering Department Courses
INSERT INTO
    course (title, code, department_id)
VALUES (
        'Data Structures and Algorithms',
        'SE101',
        1
    ),
    (
        'Object-Oriented Programming',
        'SE102',
        1
    ),
    (
        'Software Engineering Principles',
        'SE103',
        1
    );

\echo ' ✓ SE courses inserted'

-- Networking and Security Department Courses
INSERT INTO
    course (title, code, department_id)
VALUES (
        'Network Fundamentals',
        'NS101',
        2
    ),
    (
        'Cybersecurity and Cryptography',
        'NS102',
        2
    ),
    (
        'Wireless Networks and Security',
        'NS103',
        2
    );

\echo ' ✓ NS courses inserted'

-- Information Systems Management Department Courses
INSERT INTO
    course (title, code, department_id)
VALUES (
        'Business Information Systems',
        'ISM101',
        3
    ),
    (
        'Database Management and Design',
        'ISM102',
        3
    ),
    (
        'Enterprise Resource Planning',
        'ISM103',
        3
    );


\echo '    ✓ ISM courses inserted'
\echo '    ✓ Total 9 courses inserted'

\echo '    [5/7] Inserting Students (15 per department = 45 total)...'

-- ============================================================================
-- STUDENTS (15 per department = 45 total)
-- ============================================================================

\echo ' - SE Students (15)...'

-- Software Engineering Students
INSERT INTO
    "user" (
        name,
        telephone,
        email,
        password,
        department_id,
        role_id,
        is_active
    )
VALUES (
        'Chidubem Okoye',
        '+234-801-111-0001',
        'chidubem.okoye@student.university.edu',
        'hashed_pass_se_001',
        1,
        1,
        TRUE
    ),
    (
        'Amara Nwankwo',
        '+234-801-111-0002',
        'amara.nwankwo@student.university.edu',
        'hashed_pass_se_002',
        1,
        1,
        TRUE
    ),
    (
        'Tunde Akanji',
        '+234-801-111-0003',
        'tunde.akanji@student.university.edu',
        'hashed_pass_se_003',
        1,
        1,
        TRUE
    ),
    (
        'Zainab Mohammed',
        '+234-801-111-0004',
        'zainab.mohammed@student.university.edu',
        'hashed_pass_se_004',
        1,
        1,
        TRUE
    ),
    (
        'Okechukwu Eze',
        '+234-801-111-0005',
        'okechukwu.eze@student.university.edu',
        'hashed_pass_se_005',
        1,
        1,
        TRUE
    ),
    (
        'Chioma Oduya',
        '+234-801-111-0006',
        'chioma.oduya@student.university.edu',
        'hashed_pass_se_006',
        1,
        1,
        TRUE
    ),
    (
        'Adebayo Oluwaseun',
        '+234-801-111-0007',
        'adebayo.oluwaseun@student.university.edu',
        'hashed_pass_se_007',
        1,
        1,
        TRUE
    ),
    (
        'Nneka Ifeanyi',
        '+234-801-111-0008',
        'nneka.ifeanyi@student.university.edu',
        'hashed_pass_se_008',
        1,
        1,
        TRUE
    ),
    (
        'Yusuf Abdulrahman',
        '+234-801-111-0009',
        'yusuf.abdulrahman@student.university.edu',
        'hashed_pass_se_009',
        1,
        1,
        TRUE
    ),
    (
        'Fatima Hassan',
        '+234-801-111-0010',
        'fatima.hassan@student.university.edu',
        'hashed_pass_se_010',
        1,
        1,
        TRUE
    ),
    (
        'Emeka Ndiaye',
        '+234-801-111-0011',
        'emeka.ndiaye@student.university.edu',
        'hashed_pass_se_011',
        1,
        1,
        TRUE
    ),
    (
        'Blessing Chukwu',
        '+234-801-111-0012',
        'blessing.chukwu@student.university.edu',
        'hashed_pass_se_012',
        1,
        1,
        TRUE
    ),
    (
        'Karim Suleiman',
        '+234-801-111-0013',
        'karim.suleiman@student.university.edu',
        'hashed_pass_se_013',
        1,
        1,
        TRUE
    ),
    (
        'Gladys Mwangi',
        '+234-801-111-0014',
        'gladys.mwangi@student.university.edu',
        'hashed_pass_se_014',
        1,
        1,
        TRUE
    ),
    (
        'Daniel Okoro',
        '+234-801-111-0015',
        'daniel.okoro@student.university.edu',
        'hashed_pass_se_015',
        1,
        1,
        TRUE
    );

-- Networking and Security Students
INSERT INTO
    "user" (
        name,
        telephone,
        email,
        password,
        department_id,
        role_id,
        is_active
    )
VALUES (
        'Rasheed Adeyinka',
        '+234-801-222-0001',
        'rasheed.adeyinka@student.university.edu',
        'hashed_pass_ns_001',
        2,
        1,
        TRUE
    ),
    (
        'Zainab Yakubu',
        '+234-801-222-0002',
        'zainab.yakubu@student.university.edu',
        'hashed_pass_ns_002',
        2,
        1,
        TRUE
    ),
    (
        'Ibrahim Musa',
        '+234-801-222-0003',
        'ibrahim.musa@student.university.edu',
        'hashed_pass_ns_003',
        2,
        1,
        TRUE
    ),
    (
        'Aisha Garba',
        '+234-801-222-0004',
        'aisha.garba@student.university.edu',
        'hashed_pass_ns_004',
        2,
        1,
        TRUE
    ),
    (
        'Tariq Al-Rashid',
        '+234-801-222-0005',
        'tariq.alrashid@student.university.edu',
        'hashed_pass_ns_005',
        2,
        1,
        TRUE
    ),
    (
        'Kehinde Oladele',
        '+234-801-222-0006',
        'kehinde.oladele@student.university.edu',
        'hashed_pass_ns_006',
        2,
        1,
        TRUE
    ),
    (
        'Hadiza Malam',
        '+234-801-222-0007',
        'hadiza.malam@student.university.edu',
        'hashed_pass_ns_007',
        2,
        1,
        TRUE
    ),
    (
        'Caleb Obi',
        '+234-801-222-0008',
        'caleb.obi@student.university.edu',
        'hashed_pass_ns_008',
        2,
        1,
        TRUE
    ),
    (
        'Amina Khan',
        '+234-801-222-0009',
        'amina.khan@student.university.edu',
        'hashed_pass_ns_009',
        2,
        1,
        TRUE
    ),
    (
        'Festus Adebola',
        '+234-801-222-0010',
        'festus.adebola@student.university.edu',
        'hashed_pass_ns_010',
        2,
        1,
        TRUE
    ),
    (
        'Nadia Hussain',
        '+234-801-222-0011',
        'nadia.hussain@student.university.edu',
        'hashed_pass_ns_011',
        2,
        1,
        TRUE
    ),
    (
        'Olumide Ajayi',
        '+234-801-222-0012',
        'olumide.ajayi@student.university.edu',
        'hashed_pass_ns_012',
        2,
        1,
        TRUE
    ),
    (
        'Safiya Adamu',
        '+234-801-222-0013',
        'safiya.adamu@student.university.edu',
        'hashed_pass_ns_013',
        2,
        1,
        TRUE
    ),
    (
        'Segun Olayinka',
        '+234-801-222-0014',
        'segun.olayinka@student.university.edu',
        'hashed_pass_ns_014',
        2,
        1,
        TRUE
    ),
    (
        'Leah Dada',
        '+234-801-222-0015',
        'leah.dada@student.university.edu',
        'hashed_pass_ns_015',
        2,
        1,
        TRUE
    );

\echo '        - NS Students (15)...'
\echo '        - ISM Students (15)...'

-- Information Systems Management Students
INSERT INTO
    "user" (
        name,
        telephone,
        email,
        password,
        department_id,
        role_id,
        is_active
    )
VALUES (
        'Chidinma Okeke',
        '+234-801-333-0001',
        'chidinma.okeke@student.university.edu',
        'hashed_pass_ism_001',
        3,
        1,
        TRUE
    ),
    (
        'Femi Olayinka',
        '+234-801-333-0002',
        'femi.olayinka@student.university.edu',
        'hashed_pass_ism_002',
        3,
        1,
        TRUE
    ),
    (
        'Ngozi Nwosu',
        '+234-801-333-0003',
        'ngozi.nwosu@student.university.edu',
        'hashed_pass_ism_003',
        3,
        1,
        TRUE
    ),
    (
        'Adekunle Bello',
        '+234-801-333-0004',
        'adekunle.bello@student.university.edu',
        'hashed_pass_ism_004',
        3,
        1,
        TRUE
    ),
    (
        'Patience Okoro',
        '+234-801-333-0005',
        'patience.okoro@student.university.edu',
        'hashed_pass_ism_005',
        3,
        1,
        TRUE
    ),
    (
        'Malik Abdu',
        '+234-801-333-0006',
        'malik.abdu@student.university.edu',
        'hashed_pass_ism_006',
        3,
        1,
        TRUE
    ),
    (
        'Grace Kumasi',
        '+234-801-333-0007',
        'grace.kumasi@student.university.edu',
        'hashed_pass_ism_007',
        3,
        1,
        TRUE
    ),
    (
        'Adeyemi Opara',
        '+234-801-333-0008',
        'adeyemi.opara@student.university.edu',
        'hashed_pass_ism_008',
        3,
        1,
        TRUE
    ),
    (
        'Juliana Adeyele',
        '+234-801-333-0009',
        'juliana.adeyele@student.university.edu',
        'hashed_pass_ism_009',
        3,
        1,
        TRUE
    ),
    (
        'Marcus Ikechukwu',
        '+234-801-333-0010',
        'marcus.ikechukwu@student.university.edu',
        'hashed_pass_ism_010',
        3,
        1,
        TRUE
    ),
    (
        'Ifunanya Eze',
        '+234-801-333-0011',
        'ifunanya.eze@student.university.edu',
        'hashed_pass_ism_011',
        3,
        1,
        TRUE
    ),
    (
        'Solomon Taiwo',
        '+234-801-333-0012',
        'solomon.taiwo@student.university.edu',
        'hashed_pass_ism_012',
        3,
        1,
        TRUE
    ),
    (
        'Dina Afolayan',
        '+234-801-333-0013',
        'dina.afolayan@student.university.edu',
        'hashed_pass_ism_013',
        3,
        1,
        TRUE
    ),
    (
        'Chinedu Okafor',
        '+234-801-333-0014',
        'chinedu.okafor@student.university.edu',
        'hashed_pass_ism_014',
        3,
        1,
        TRUE
    ),
    (
        'Yetunde Oluwole',
        '+234-801-333-0015',
        'yetunde.oluwole@student.university.edu',
        'hashed_pass_ism_015',
        3,
        1,
        TRUE
    );


\echo '    ✓ Total 45 students inserted (15 per department)'

\echo '    [6/7] Creating Events (15 events: 5 per course, 3 courses, 3 departments)...'

-- ============================================================================
-- EVENTS (5 classes per course = 15 per department)
-- ============================================================================

\echo ' - SE events (15 classes)...'

-- Software Engineering - Data Structures and Algorithms (SE101) - 5 classes
INSERT INTO
    event (
        name,
        type,
        status,
        location,
        start_at,
        stop_at,
        organizer_id,
        course_id
    )
VALUES (
        'SE101 - Class 1: Arrays and Linked Lists',
        'class',
        'completed',
        'Room 301',
        '2026-02-01 09:00:00+01:00',
        '2026-02-01 10:30:00+01:00',
        1,
        1
    ),
    (
        'SE101 - Class 2: Stacks and Queues',
        'class',
        'completed',
        'Room 301',
        '2026-02-02 09:00:00+01:00',
        '2026-02-02 10:30:00+01:00',
        1,
        1
    ),
    (
        'SE101 - Class 3: Trees and Graphs',
        'class',
        'completed',
        'Room 301',
        '2026-02-03 09:00:00+01:00',
        '2026-02-03 10:30:00+01:00',
        1,
        1
    ),
    (
        'SE101 - Class 4: Sorting Algorithms',
        'class',
        'running',
        'Room 301',
        '2026-02-04 09:00:00+01:00',
        '2026-02-04 10:30:00+01:00',
        1,
        1
    ),
    (
        'SE101 - Class 5: Dynamic Programming',
        'class',
        'scheduled',
        'Room 301',
        '2026-02-05 09:00:00+01:00',
        '2026-02-05 10:30:00+01:00',
        1,
        1
    );

-- Software Engineering - Object-Oriented Programming (SE102) - 5 classes
INSERT INTO
    event (
        name,
        type,
        status,
        location,
        start_at,
        stop_at,
        organizer_id,
        course_id
    )
VALUES (
        'SE102 - Class 1: Classes and Objects',
        'class',
        'completed',
        'Room 302',
        '2026-02-01 11:00:00+01:00',
        '2026-02-01 12:30:00+01:00',
        1,
        2
    ),
    (
        'SE102 - Class 2: Inheritance and Polymorphism',
        'class',
        'completed',
        'Room 302',
        '2026-02-02 11:00:00+01:00',
        '2026-02-02 12:30:00+01:00',
        1,
        2
    ),
    (
        'SE102 - Class 3: Encapsulation and Abstraction',
        'class',
        'completed',
        'Room 302',
        '2026-02-03 11:00:00+01:00',
        '2026-02-03 12:30:00+01:00',
        1,
        2
    ),
    (
        'SE102 - Class 4: Design Patterns',
        'class',
        'running',
        'Room 302',
        '2026-02-04 11:00:00+01:00',
        '2026-02-04 12:30:00+01:00',
        1,
        2
    ),
    (
        'SE102 - Class 5: SOLID Principles',
        'class',
        'scheduled',
        'Room 302',
        '2026-02-05 11:00:00+01:00',
        '2026-02-05 12:30:00+01:00',
        1,
        2
    );

-- Software Engineering - Software Engineering Principles (SE103) - 5 classes
INSERT INTO
    event (
        name,
        type,
        status,
        location,
        start_at,
        stop_at,
        organizer_id,
        course_id
    )
VALUES (
        'SE103 - Class 1: SDLC Overview',
        'class',
        'completed',
        'Room 303',
        '2026-02-01 14:00:00+01:00',
        '2026-02-01 15:30:00+01:00',
        1,
        3
    ),
    (
        'SE103 - Class 2: Requirements Analysis',
        'class',
        'completed',
        'Room 303',
        '2026-02-02 14:00:00+01:00',
        '2026-02-02 15:30:00+01:00',
        1,
        3
    ),
    (
        'SE103 - Class 3: System Design',
        'class',
        'completed',
        'Room 303',
        '2026-02-03 14:00:00+01:00',
        '2026-02-03 15:30:00+01:00',
        1,
        3
    ),
    (
        'SE103 - Class 4: Testing Strategies',
        'class',
        'running',
        'Room 303',
        '2026-02-04 14:00:00+01:00',
        '2026-02-04 15:30:00+01:00',
        1,
        3
    ),
    (
        'SE103 - Class 5: Deployment and Maintenance',
        'class',
        'scheduled',
        'Room 303',
        '2026-02-05 14:00:00+01:00',
        '2026-02-05 15:30:00+01:00',
        1,
        3
    );

\echo ' - NS events (15 classes)...'

-- Networking and Security - Network Fundamentals (NS101) - 5 classes
INSERT INTO
    event (
        name,
        type,
        status,
        location,
        start_at,
        stop_at,
        organizer_id,
        course_id
    )
VALUES (
        'NS101 - Class 1: OSI Model',
        'class',
        'completed',
        'Room 401',
        '2026-02-01 09:00:00+01:00',
        '2026-02-01 10:30:00+01:00',
        2,
        4
    ),
    (
        'NS101 - Class 2: TCP/IP Protocol Suite',
        'class',
        'completed',
        'Room 401',
        '2026-02-02 09:00:00+01:00',
        '2026-02-02 10:30:00+01:00',
        2,
        4
    ),
    (
        'NS101 - Class 3: IP Addressing and Subnetting',
        'class',
        'completed',
        'Room 401',
        '2026-02-03 09:00:00+01:00',
        '2026-02-03 10:30:00+01:00',
        2,
        4
    ),
    (
        'NS101 - Class 4: Routing Concepts',
        'class',
        'running',
        'Room 401',
        '2026-02-04 09:00:00+01:00',
        '2026-02-04 10:30:00+01:00',
        2,
        4
    ),
    (
        'NS101 - Class 5: DNS and DHCP',
        'class',
        'scheduled',
        'Room 401',
        '2026-02-05 09:00:00+01:00',
        '2026-02-05 10:30:00+01:00',
        2,
        4
    );

-- Networking and Security - Cybersecurity and Cryptography (NS102) - 5 classes
INSERT INTO
    event (
        name,
        type,
        status,
        location,
        start_at,
        stop_at,
        organizer_id,
        course_id
    )
VALUES (
        'NS102 - Class 1: Security Fundamentals',
        'class',
        'completed',
        'Room 402',
        '2026-02-01 11:00:00+01:00',
        '2026-02-01 12:30:00+01:00',
        2,
        5
    ),
    (
        'NS102 - Class 2: Symmetric Encryption',
        'class',
        'completed',
        'Room 402',
        '2026-02-02 11:00:00+01:00',
        '2026-02-02 12:30:00+01:00',
        2,
        5
    ),
    (
        'NS102 - Class 3: Asymmetric Encryption',
        'class',
        'completed',
        'Room 402',
        '2026-02-03 11:00:00+01:00',
        '2026-02-03 12:30:00+01:00',
        2,
        5
    ),
    (
        'NS102 - Class 4: Hash Functions and Digital Signatures',
        'class',
        'running',
        'Room 402',
        '2026-02-04 11:00:00+01:00',
        '2026-02-04 12:30:00+01:00',
        2,
        5
    ),
    (
        'NS102 - Class 5: Authentication and Access Control',
        'class',
        'scheduled',
        'Room 402',
        '2026-02-05 11:00:00+01:00',
        '2026-02-05 12:30:00+01:00',
        2,
        5
    );

-- Networking and Security - Wireless Networks and Security (NS103) - 5 classes
INSERT INTO
    event (
        name,
        type,
        status,
        location,
        start_at,
        stop_at,
        organizer_id,
        course_id
    )
VALUES (
        'NS103 - Class 1: Wireless Standards and Technologies',
        'class',
        'completed',
        'Room 403',
        '2026-02-01 14:00:00+01:00',
        '2026-02-01 15:30:00+01:00',
        2,
        6
    ),
    (
        'NS103 - Class 2: Wi-Fi Security',
        'class',
        'completed',
        'Room 403',
        '2026-02-02 14:00:00+01:00',
        '2026-02-02 15:30:00+01:00',
        2,
        6
    ),
    (
        'NS103 - Class 3: Mobile Network Security',
        'class',
        'completed',
        'Room 403',
        '2026-02-03 14:00:00+01:00',
        '2026-02-03 15:30:00+01:00',
        2,
        6
    ),
    (
        'NS103 - Class 4: IoT and Wireless Threats',
        'class',
        'running',
        'Room 403',
        '2026-02-04 14:00:00+01:00',
        '2026-02-04 15:30:00+01:00',
        2,
        6
    ),
    (
        'NS103 - Class 5: Wireless Best Practices',
        'class',
        'scheduled',
        'Room 403',
        '2026-02-05 14:00:00+01:00',
        '2026-02-05 15:30:00+01:00',
        2,
        6
    );

\echo ' - ISM events (15 classes)...'

-- Information Systems Management - Business Information Systems (ISM101) - 5 classes
INSERT INTO
    event (
        name,
        type,
        status,
        location,
        start_at,
        stop_at,
        organizer_id,
        course_id
    )
VALUES (
        'ISM101 - Class 1: Introduction to BIS',
        'class',
        'completed',
        'Room 501',
        '2026-02-01 09:00:00+01:00',
        '2026-02-01 10:30:00+01:00',
        3,
        7
    ),
    (
        'ISM101 - Class 2: Information Systems Strategy',
        'class',
        'completed',
        'Room 501',
        '2026-02-02 09:00:00+01:00',
        '2026-02-02 10:30:00+01:00',
        3,
        7
    ),
    (
        'ISM101 - Class 3: Business Process Management',
        'class',
        'completed',
        'Room 501',
        '2026-02-03 09:00:00+01:00',
        '2026-02-03 10:30:00+01:00',
        3,
        7
    ),
    (
        'ISM101 - Class 4: IT Governance and Risk',
        'class',
        'running',
        'Room 501',
        '2026-02-04 09:00:00+01:00',
        '2026-02-04 10:30:00+01:00',
        3,
        7
    ),
    (
        'ISM101 - Class 5: Digital Transformation',
        'class',
        'scheduled',
        'Room 501',
        '2026-02-05 09:00:00+01:00',
        '2026-02-05 10:30:00+01:00',
        3,
        7
    );

-- Information Systems Management - Database Management and Design (ISM102) - 5 classes
INSERT INTO
    event (
        name,
        type,
        status,
        location,
        start_at,
        stop_at,
        organizer_id,
        course_id
    )
VALUES (
        'ISM102 - Class 1: Database Concepts',
        'class',
        'completed',
        'Room 502',
        '2026-02-01 11:00:00+01:00',
        '2026-02-01 12:30:00+01:00',
        3,
        8
    ),
    (
        'ISM102 - Class 2: Data Modeling and ER Diagrams',
        'class',
        'completed',
        'Room 502',
        '2026-02-02 11:00:00+01:00',
        '2026-02-02 12:30:00+01:00',
        3,
        8
    ),
    (
        'ISM102 - Class 3: SQL and Query Optimization',
        'class',
        'completed',
        'Room 502',
        '2026-02-03 11:00:00+01:00',
        '2026-02-03 12:30:00+01:00',
        3,
        8
    ),
    (
        'ISM102 - Class 4: Database Administration',
        'class',
        'running',
        'Room 502',
        '2026-02-04 11:00:00+01:00',
        '2026-02-04 12:30:00+01:00',
        3,
        8
    ),
    (
        'ISM102 - Class 5: NoSQL Databases',
        'class',
        'scheduled',
        'Room 502',
        '2026-02-05 11:00:00+01:00',
        '2026-02-05 12:30:00+01:00',
        3,
        8
    );

-- Information Systems Management - Enterprise Resource Planning (ISM103) - 5 classes
INSERT INTO
    event (
        name,
        type,
        status,
        location,
        start_at,
        stop_at,
        organizer_id,
        course_id
    )
VALUES (
        'ISM103 - Class 1: ERP Systems Overview',
        'class',
        'completed',
        'Room 503',
        '2026-02-01 14:00:00+01:00',
        '2026-02-01 15:30:00+01:00',
        3,
        9
    ),
    (
        'ISM103 - Class 2: SAP and Oracle ERP',
        'class',
        'completed',
        'Room 503',
        '2026-02-02 14:00:00+01:00',
        '2026-02-02 15:30:00+01:00',
        3,
        9
    ),
    (
        'ISM103 - Class 3: ERP Implementation',
        'class',
        'completed',
        'Room 503',
        '2026-02-03 14:00:00+01:00',
        '2026-02-03 15:30:00+01:00',
        3,
        9
    ),
    (
        'ISM103 - Class 4: ERP Best Practices',
        'class',
        'running',
        'Room 503',
        '2026-02-04 14:00:00+01:00',
        '2026-02-04 15:30:00+01:00',
        3,
        9
    ),
    (
        'ISM103 - Class 5: Cloud ERP Solutions',
        'class',
        'scheduled',
        'Room 503',
        '2026-02-05 14:00:00+01:00',
        '2026-02-05 15:30:00+01:00',
        3,
        9
    );

-- ============================================================================
-- REGISTRATIONS (All students registered for all events in their department)
-- ============================================================================
\echo ''
\echo '    [Step 7/9] Inserting registrations (students linked to events)...'
\echo '        Registering SE students (15 students × 15 SE events = 225 registrations)...'

-- SE Students registered for SE courses (user_ids 5-19 for SE department students)
INSERT INTO
    registration (
        event_id,
        user_id,
        status,
        completed_at
    )
SELECT e.id, u.id, 'completed', '2026-02-01 10:45:00+01:00'
FROM event e, "user" u
WHERE
    e.course_id IN (1, 2, 3)
    AND u.department_id = 1
    AND u.role_id = 1;

\echo '        ✓ SE registrations complete'
\echo '        Registering NS students (15 students × 15 NS events = 225 registrations)...'

-- NS Students registered for NS courses (user_ids 20-34 for NS department students)
INSERT INTO
    registration (
        event_id,
        user_id,
        status,
        completed_at
    )
SELECT e.id, u.id, 'completed', '2026-02-01 10:45:00+01:00'
FROM event e, "user" u
WHERE
    e.course_id IN (4, 5, 6)
    AND u.department_id = 2
    AND u.role_id = 1;

\echo '        ✓ NS registrations complete'
\echo '        Registering ISM students (15 students × 15 ISM events = 225 registrations)...'

-- ISM Students registered for ISM courses (user_ids 35-49 for ISM department students)
INSERT INTO
    registration (
        event_id,
        user_id,
        status,
        completed_at
    )
SELECT e.id, u.id, 'completed', '2026-02-01 10:45:00+01:00'
FROM event e, "user" u
WHERE
    e.course_id IN (7, 8, 9)
    AND u.department_id = 3
    AND u.role_id = 1;

\echo '        ✓ ISM registrations complete'
\echo '    ✓ Total: 675 registrations inserted (45 students × 15 events)'

-- ============================================================================
-- QR CODES (One per event)
-- ============================================================================
\echo '' \echo ' [Step 8/9] Inserting QR codes (one per event)...'

INSERT INTO
    qr_code (code, event_id, expired_at)
VALUES (
        'QR_SE101_CLASS1_20260201090000',
        1,
        '2026-02-06 10:45:00+01:00'
    ),
    (
        'QR_SE101_CLASS2_20260202090000',
        2,
        '2026-02-07 10:45:00+01:00'
    ),
    (
        'QR_SE101_CLASS3_20260203090000',
        3,
        '2026-02-08 10:45:00+01:00'
    ),
    (
        'QR_SE101_CLASS4_20260204090000',
        4,
        '2026-02-09 10:45:00+01:00'
    ),
    (
        'QR_SE101_CLASS5_20260205090000',
        5,
        '2026-02-10 10:45:00+01:00'
    ),
    (
        'QR_SE102_CLASS1_20260201110000',
        6,
        '2026-02-06 12:45:00+01:00'
    ),
    (
        'QR_SE102_CLASS2_20260202110000',
        7,
        '2026-02-07 12:45:00+01:00'
    ),
    (
        'QR_SE102_CLASS3_20260203110000',
        8,
        '2026-02-08 12:45:00+01:00'
    ),
    (
        'QR_SE102_CLASS4_20260204110000',
        9,
        '2026-02-09 12:45:00+01:00'
    ),
    (
        'QR_SE102_CLASS5_20260205110000',
        10,
        '2026-02-10 12:45:00+01:00'
    ),
    (
        'QR_SE103_CLASS1_20260201140000',
        11,
        '2026-02-06 15:45:00+01:00'
    ),
    (
        'QR_SE103_CLASS2_20260202140000',
        12,
        '2026-02-07 15:45:00+01:00'
    ),
    (
        'QR_SE103_CLASS3_20260203140000',
        13,
        '2026-02-08 15:45:00+01:00'
    ),
    (
        'QR_SE103_CLASS4_20260204140000',
        14,
        '2026-02-09 15:45:00+01:00'
    ),
    (
        'QR_SE103_CLASS5_20260205140000',
        15,
        '2026-02-10 15:45:00+01:00'
    ),
    (
        'QR_NS101_CLASS1_20260201090000',
        16,
        '2026-02-06 10:45:00+01:00'
    ),
    (
        'QR_NS101_CLASS2_20260202090000',
        17,
        '2026-02-07 10:45:00+01:00'
    ),
    (
        'QR_NS101_CLASS3_20260203090000',
        18,
        '2026-02-08 10:45:00+01:00'
    ),
    (
        'QR_NS101_CLASS4_20260204090000',
        19,
        '2026-02-09 10:45:00+01:00'
    ),
    (
        'QR_NS101_CLASS5_20260205090000',
        20,
        '2026-02-10 10:45:00+01:00'
    ),
    (
        'QR_NS102_CLASS1_20260201110000',
        21,
        '2026-02-06 12:45:00+01:00'
    ),
    (
        'QR_NS102_CLASS2_20260202110000',
        22,
        '2026-02-07 12:45:00+01:00'
    ),
    (
        'QR_NS102_CLASS3_20260203110000',
        23,
        '2026-02-08 12:45:00+01:00'
    ),
    (
        'QR_NS102_CLASS4_20260204110000',
        24,
        '2026-02-09 12:45:00+01:00'
    ),
    (
        'QR_NS102_CLASS5_20260205110000',
        25,
        '2026-02-10 12:45:00+01:00'
    ),
    (
        'QR_NS103_CLASS1_20260201140000',
        26,
        '2026-02-06 15:45:00+01:00'
    ),
    (
        'QR_NS103_CLASS2_20260202140000',
        27,
        '2026-02-07 15:45:00+01:00'
    ),
    (
        'QR_NS103_CLASS3_20260203140000',
        28,
        '2026-02-08 15:45:00+01:00'
    ),
    (
        'QR_NS103_CLASS4_20260204140000',
        29,
        '2026-02-09 15:45:00+01:00'
    ),
    (
        'QR_NS103_CLASS5_20260205140000',
        30,
        '2026-02-10 15:45:00+01:00'
    ),
    (
        'QR_ISM101_CLASS1_20260201090000',
        31,
        '2026-02-06 10:45:00+01:00'
    ),
    (
        'QR_ISM101_CLASS2_20260202090000',
        32,
        '2026-02-07 10:45:00+01:00'
    ),
    (
        'QR_ISM101_CLASS3_20260203090000',
        33,
        '2026-02-08 10:45:00+01:00'
    ),
    (
        'QR_ISM101_CLASS4_20260204090000',
        34,
        '2026-02-09 10:45:00+01:00'
    ),
    (
        'QR_ISM101_CLASS5_20260205090000',
        35,
        '2026-02-10 10:45:00+01:00'
    ),
    (
        'QR_ISM102_CLASS1_20260201110000',
        36,
        '2026-02-06 12:45:00+01:00'
    ),
    (
        'QR_ISM102_CLASS2_20260202110000',
        37,
        '2026-02-07 12:45:00+01:00'
    ),
    (
        'QR_ISM102_CLASS3_20260203110000',
        38,
        '2026-02-08 12:45:00+01:00'
    ),
    (
        'QR_ISM102_CLASS4_20260204110000',
        39,
        '2026-02-09 12:45:00+01:00'
    ),
    (
        'QR_ISM102_CLASS5_20260205110000',
        40,
        '2026-02-10 12:45:00+01:00'
    ),
    (
        'QR_ISM103_CLASS1_20260201140000',
        41,
        '2026-02-06 15:45:00+01:00'
    ),
    (
        'QR_ISM103_CLASS2_20260202140000',
        42,
        '2026-02-07 15:45:00+01:00'
    ),
    (
        'QR_ISM103_CLASS3_20260203140000',
        43,
        '2026-02-08 15:45:00+01:00'
    ),
    (
        'QR_ISM103_CLASS4_20260204140000',
        44,
        '2026-02-09 15:45:00+01:00'
    ),
    (
        'QR_ISM103_CLASS5_20260205140000',
        45,
        '2026-02-10 15:45:00+01:00'
    );

\echo ' ✓ 45 QR codes inserted'

-- ============================================================================
-- PRESENCE DATA (Attendance with random patterns)
-- ============================================================================
\echo ''
\echo '    [Step 9/9] Inserting presence/attendance data (1500+ records)...'
\echo '        Generating attendance records for Software Engineering department...'

-- Software Engineering - Random attendance with some students absent/late
INSERT INTO
    presence (
        user_id,
        event_id,
        status,
        scanned_at
    )
VALUES
    -- SE101 Class 1
    (
        5,
        1,
        'present',
        '2026-02-01 09:05:00+01:00'
    ),
    (
        6,
        1,
        'present',
        '2026-02-01 09:08:00+01:00'
    ),
    (
        7,
        1,
        'late',
        '2026-02-01 09:25:00+01:00'
    ),
    (
        8,
        1,
        'present',
        '2026-02-01 09:03:00+01:00'
    ),
    (9, 1, 'absent', NULL),
    (
        10,
        1,
        'present',
        '2026-02-01 09:10:00+01:00'
    ),
    (
        11,
        1,
        'present',
        '2026-02-01 09:07:00+01:00'
    ),
    (
        12,
        1,
        'late',
        '2026-02-01 09:35:00+01:00'
    ),
    (
        13,
        1,
        'present',
        '2026-02-01 09:04:00+01:00'
    ),
    (
        14,
        1,
        'present',
        '2026-02-01 09:02:00+01:00'
    ),
    (15, 1, 'absent', NULL),
    (
        16,
        1,
        'present',
        '2026-02-01 09:09:00+01:00'
    ),
    (
        17,
        1,
        'present',
        '2026-02-01 09:06:00+01:00'
    ),
    (
        18,
        1,
        'present',
        '2026-02-01 09:11:00+01:00'
    ),
    (
        19,
        1,
        'late',
        '2026-02-01 09:30:00+01:00'
    ),

-- SE101 Class 2
(
    5,
    2,
    'present',
    '2026-02-02 09:04:00+01:00'
),
(
    6,
    2,
    'present',
    '2026-02-02 09:07:00+01:00'
),
(
    7,
    2,
    'present',
    '2026-02-02 09:05:00+01:00'
),
(8, 2, 'absent', NULL),
(
    9,
    2,
    'present',
    '2026-02-02 09:09:00+01:00'
),
(
    10,
    2,
    'late',
    '2026-02-02 09:28:00+01:00'
),
(
    11,
    2,
    'present',
    '2026-02-02 09:03:00+01:00'
),
(
    12,
    2,
    'present',
    '2026-02-02 09:08:00+01:00'
),
(
    13,
    2,
    'present',
    '2026-02-02 09:06:00+01:00'
),
(14, 2, 'absent', NULL),
(
    15,
    2,
    'present',
    '2026-02-02 09:10:00+01:00'
),
(
    16,
    2,
    'present',
    '2026-02-02 09:02:00+01:00'
),
(
    17,
    2,
    'late',
    '2026-02-02 09:32:00+01:00'
),
(
    18,
    2,
    'present',
    '2026-02-02 09:05:00+01:00'
),
(
    19,
    2,
    'present',
    '2026-02-02 09:07:00+01:00'
),

-- SE101 Class 3
(
    5,
    3,
    'present',
    '2026-02-03 09:03:00+01:00'
),
(
    6,
    3,
    'late',
    '2026-02-03 09:27:00+01:00'
),
(
    7,
    3,
    'present',
    '2026-02-03 09:08:00+01:00'
),
(
    8,
    3,
    'present',
    '2026-02-03 09:05:00+01:00'
),
(9, 3, 'absent', NULL),
(
    10,
    3,
    'present',
    '2026-02-03 09:09:00+01:00'
),
(
    11,
    3,
    'present',
    '2026-02-03 09:04:00+01:00'
),
(
    12,
    3,
    'present',
    '2026-02-03 09:06:00+01:00'
),
(
    13,
    3,
    'present',
    '2026-02-03 09:02:00+01:00'
),
(
    14,
    3,
    'present',
    '2026-02-03 09:11:00+01:00'
),
(15, 3, 'absent', NULL),
(
    16,
    3,
    'late',
    '2026-02-03 09:26:00+01:00'
),
(
    17,
    3,
    'present',
    '2026-02-03 09:07:00+01:00'
),
(18, 3, 'absent', NULL),
(
    19,
    3,
    'present',
    '2026-02-03 09:04:00+01:00'
),

-- SE102 Class 1
(
    5,
    6,
    'present',
    '2026-02-01 11:03:00+01:00'
),
(
    6,
    6,
    'present',
    '2026-02-01 11:05:00+01:00'
),
(
    7,
    6,
    'present',
    '2026-02-01 11:07:00+01:00'
),
(
    8,
    6,
    'late',
    '2026-02-01 11:35:00+01:00'
),
(
    9,
    6,
    'present',
    '2026-02-01 11:04:00+01:00'
),
(
    10,
    6,
    'present',
    '2026-02-01 11:08:00+01:00'
),
(11, 6, 'absent', NULL),
(
    12,
    6,
    'present',
    '2026-02-01 11:06:00+01:00'
),
(
    13,
    6,
    'present',
    '2026-02-01 11:02:00+01:00'
),
(
    14,
    6,
    'present',
    '2026-02-01 11:09:00+01:00'
),
(
    15,
    6,
    'present',
    '2026-02-01 11:05:00+01:00'
),
(
    16,
    6,
    'present',
    '2026-02-01 11:03:00+01:00'
),
(17, 6, 'absent', NULL),
(
    18,
    6,
    'present',
    '2026-02-01 11:07:00+01:00'
),
(
    19,
    6,
    'late',
    '2026-02-01 11:33:00+01:00'
),

-- SE102 Class 2
(
    5,
    7,
    'present',
    '2026-02-02 11:04:00+01:00'
),
(6, 7, 'absent', NULL),
(
    7,
    7,
    'present',
    '2026-02-02 11:06:00+01:00'
),
(
    8,
    7,
    'present',
    '2026-02-02 11:05:00+01:00'
),
(
    9,
    7,
    'late',
    '2026-02-02 11:28:00+01:00'
),
(
    10,
    7,
    'present',
    '2026-02-02 11:03:00+01:00'
),
(
    11,
    7,
    'present',
    '2026-02-02 11:07:00+01:00'
),
(
    12,
    7,
    'present',
    '2026-02-02 11:02:00+01:00'
),
(
    13,
    7,
    'present',
    '2026-02-02 11:08:00+01:00'
),
(14, 7, 'absent', NULL),
(
    15,
    7,
    'present',
    '2026-02-02 11:04:00+01:00'
),
(
    16,
    7,
    'late',
    '2026-02-02 11:29:00+01:00'
),
(
    17,
    7,
    'present',
    '2026-02-02 11:05:00+01:00'
),
(
    18,
    7,
    'present',
    '2026-02-02 11:06:00+01:00'
),
(
    19,
    7,
    'present',
    '2026-02-02 11:03:00+01:00'
),

-- SE102 Class 3
(
    5,
    8,
    'present',
    '2026-02-03 11:05:00+01:00'
),
(
    6,
    8,
    'present',
    '2026-02-03 11:04:00+01:00'
),
(7, 8, 'absent', NULL),
(
    8,
    8,
    'present',
    '2026-02-03 11:06:00+01:00'
),
(
    9,
    8,
    'present',
    '2026-02-03 11:03:00+01:00'
),
(
    10,
    8,
    'present',
    '2026-02-03 11:08:00+01:00'
),
(
    11,
    8,
    'late',
    '2026-02-03 11:27:00+01:00'
),
(
    12,
    8,
    'present',
    '2026-02-03 11:07:00+01:00'
),
(
    13,
    8,
    'present',
    '2026-02-03 11:02:00+01:00'
),
(
    14,
    8,
    'present',
    '2026-02-03 11:04:00+01:00'
),
(
    15,
    8,
    'present',
    '2026-02-03 11:05:00+01:00'
),
(16, 8, 'absent', NULL),
(
    17,
    8,
    'present',
    '2026-02-03 11:06:00+01:00'
),
(
    18,
    8,
    'late',
    '2026-02-03 11:31:00+01:00'
),
(
    19,
    8,
    'present',
    '2026-02-03 11:03:00+01:00'
),

-- SE103 Class 1
(
    5,
    11,
    'present',
    '2026-02-01 14:03:00+01:00'
),
(
    6,
    11,
    'present',
    '2026-02-01 14:05:00+01:00'
),
(
    7,
    11,
    'late',
    '2026-02-01 14:26:00+01:00'
),
(
    8,
    11,
    'present',
    '2026-02-01 14:04:00+01:00'
),
(
    9,
    11,
    'present',
    '2026-02-01 14:06:00+01:00'
),
(10, 11, 'absent', NULL),
(
    11,
    11,
    'present',
    '2026-02-01 14:02:00+01:00'
),
(
    12,
    11,
    'present',
    '2026-02-01 14:07:00+01:00'
),
(
    13,
    11,
    'present',
    '2026-02-01 14:05:00+01:00'
),
(
    14,
    11,
    'present',
    '2026-02-01 14:08:00+01:00'
),
(15, 11, 'absent', NULL),
(
    16,
    11,
    'present',
    '2026-02-01 14:04:00+01:00'
),
(
    17,
    11,
    'present',
    '2026-02-01 14:03:00+01:00'
),
(
    18,
    11,
    'late',
    '2026-02-01 14:32:00+01:00'
),
(
    19,
    11,
    'present',
    '2026-02-01 14:06:00+01:00'
),

-- SE103 Class 2
(
    5,
    12,
    'present',
    '2026-02-02 14:04:00+01:00'
),
(
    6,
    12,
    'present',
    '2026-02-02 14:06:00+01:00'
),
(
    7,
    12,
    'present',
    '2026-02-02 14:05:00+01:00'
),
(8, 12, 'absent', NULL),
(
    9,
    12,
    'present',
    '2026-02-02 14:03:00+01:00'
),
(
    10,
    12,
    'late',
    '2026-02-02 14:29:00+01:00'
),
(
    11,
    12,
    'present',
    '2026-02-02 14:07:00+01:00'
),
(
    12,
    12,
    'present',
    '2026-02-02 14:04:00+01:00'
),
(
    13,
    12,
    'present',
    '2026-02-02 14:02:00+01:00'
),
(
    14,
    12,
    'present',
    '2026-02-02 14:08:00+01:00'
),
(15, 12, 'absent', NULL),
(
    16,
    12,
    'present',
    '2026-02-02 14:05:00+01:00'
),
(
    17,
    12,
    'present',
    '2026-02-02 14:06:00+01:00'
),
(
    18,
    12,
    'late',
    '2026-02-02 14:30:00+01:00'
),
(
    19,
    12,
    'present',
    '2026-02-02 14:03:00+01:00'
),

-- SE103 Class 3
(
    5,
    13,
    'present',
    '2026-02-03 14:05:00+01:00'
),
(
    6,
    13,
    'present',
    '2026-02-03 14:03:00+01:00'
),
(7, 13, 'absent', NULL),
(
    8,
    13,
    'present',
    '2026-02-03 14:06:00+01:00'
),
(
    9,
    13,
    'late',
    '2026-02-03 14:28:00+01:00'
),
(
    10,
    13,
    'present',
    '2026-02-03 14:04:00+01:00'
),
(
    11,
    13,
    'present',
    '2026-02-03 14:07:00+01:00'
),
(
    12,
    13,
    'present',
    '2026-02-03 14:02:00+01:00'
),
(
    13,
    13,
    'present',
    '2026-02-03 14:05:00+01:00'
),
(
    14,
    13,
    'present',
    '2026-02-03 14:03:00+01:00'
),
(15, 13, 'absent', NULL),
(
    16,
    13,
    'present',
    '2026-02-03 14:04:00+01:00'
),
(
    17,
    13,
    'late',
    '2026-02-03 14:31:00+01:00'
),
(
    18,
    13,
    'present',
    '2026-02-03 14:06:00+01:00'
),
(
    19,
    13,
    'present',
    '2026-02-03 14:05:00+01:00'
),

-- Networking and Security - Random attendance
\echo '        ✓ SE attendance data complete'
\echo '        Generating attendance records for Networking and Security department...'
-- NS101 Class 1
(
    20,
    16,
    'present',
    '2026-02-01 09:03:00+01:00'
),
(
    21,
    16,
    'present',
    '2026-02-01 09:05:00+01:00'
),
(
    22,
    16,
    'late',
    '2026-02-01 09:26:00+01:00'
),
(
    23,
    16,
    'present',
    '2026-02-01 09:04:00+01:00'
),
(24, 16, 'absent', NULL),
(
    25,
    16,
    'present',
    '2026-02-01 09:07:00+01:00'
),
(
    26,
    16,
    'present',
    '2026-02-01 09:02:00+01:00'
),
(
    27,
    16,
    'present',
    '2026-02-01 09:08:00+01:00'
),
(
    28,
    16,
    'late',
    '2026-02-01 09:34:00+01:00'
),
(
    29,
    16,
    'present',
    '2026-02-01 09:06:00+01:00'
),
(30, 16, 'absent', NULL),
(
    31,
    16,
    'present',
    '2026-02-01 09:05:00+01:00'
),
(
    32,
    16,
    'present',
    '2026-02-01 09:03:00+01:00'
),
(
    33,
    16,
    'present',
    '2026-02-01 09:07:00+01:00'
),
(
    34,
    16,
    'present',
    '2026-02-01 09:04:00+01:00'
),

-- NS101 Class 2
(
    20,
    17,
    'present',
    '2026-02-02 09:05:00+01:00'
),
(21, 17, 'absent', NULL),
(
    22,
    17,
    'present',
    '2026-02-02 09:04:00+01:00'
),
(
    23,
    17,
    'late',
    '2026-02-02 09:29:00+01:00'
),
(
    24,
    17,
    'present',
    '2026-02-02 09:06:00+01:00'
),
(
    25,
    17,
    'present',
    '2026-02-02 09:03:00+01:00'
),
(
    26,
    17,
    'present',
    '2026-02-02 09:07:00+01:00'
),
(
    27,
    17,
    'present',
    '2026-02-02 09:02:00+01:00'
),
(28, 17, 'absent', NULL),
(
    29,
    17,
    'present',
    '2026-02-02 09:08:00+01:00'
),
(
    30,
    17,
    'late',
    '2026-02-02 09:27:00+01:00'
),
(
    31,
    17,
    'present',
    '2026-02-02 09:05:00+01:00'
),
(
    32,
    17,
    'present',
    '2026-02-02 09:04:00+01:00'
),
(
    33,
    17,
    'present',
    '2026-02-02 09:03:00+01:00'
),
(
    34,
    17,
    'present',
    '2026-02-02 09:06:00+01:00'
),

-- NS101 Class 3
(
    20,
    18,
    'late',
    '2026-02-03 09:25:00+01:00'
),
(
    21,
    18,
    'present',
    '2026-02-03 09:04:00+01:00'
),
(
    22,
    18,
    'present',
    '2026-02-03 09:05:00+01:00'
),
(
    23,
    18,
    'present',
    '2026-02-03 09:03:00+01:00'
),
(24, 18, 'absent', NULL),
(
    25,
    18,
    'present',
    '2026-02-03 09:06:00+01:00'
),
(
    26,
    18,
    'present',
    '2026-02-03 09:02:00+01:00'
),
(27, 18, 'absent', NULL),
(
    28,
    18,
    'present',
    '2026-02-03 09:07:00+01:00'
),
(
    29,
    18,
    'late',
    '2026-02-03 09:30:00+01:00'
),
(
    30,
    18,
    'present',
    '2026-02-03 09:05:00+01:00'
),
(
    31,
    18,
    'present',
    '2026-02-03 09:04:00+01:00'
),
(
    32,
    18,
    'present',
    '2026-02-03 09:08:00+01:00'
),
(
    33,
    18,
    'present',
    '2026-02-03 09:03:00+01:00'
),
(
    34,
    18,
    'present',
    '2026-02-03 09:06:00+01:00'
),

-- NS102 Class 1
(
    20,
    21,
    'present',
    '2026-02-01 11:04:00+01:00'
),
(
    21,
    21,
    'present',
    '2026-02-01 11:06:00+01:00'
),
(
    22,
    21,
    'present',
    '2026-02-01 11:03:00+01:00'
),
(23, 21, 'absent', NULL),
(
    24,
    21,
    'late',
    '2026-02-01 11:32:00+01:00'
),
(
    25,
    21,
    'present',
    '2026-02-01 11:05:00+01:00'
),
(
    26,
    21,
    'present',
    '2026-02-01 11:02:00+01:00'
),
(
    27,
    21,
    'present',
    '2026-02-01 11:07:00+01:00'
),
(
    28,
    21,
    'present',
    '2026-02-01 11:04:00+01:00'
),
(29, 21, 'absent', NULL),
(
    30,
    21,
    'present',
    '2026-02-01 11:06:00+01:00'
),
(
    31,
    21,
    'present',
    '2026-02-01 11:03:00+01:00'
),
(
    32,
    21,
    'late',
    '2026-02-01 11:33:00+01:00'
),
(
    33,
    21,
    'present',
    '2026-02-01 11:05:00+01:00'
),
(
    34,
    21,
    'present',
    '2026-02-01 11:02:00+01:00'
),

-- NS102 Class 2
(
    20,
    22,
    'present',
    '2026-02-02 11:05:00+01:00'
),
(
    21,
    22,
    'present',
    '2026-02-02 11:04:00+01:00'
),
(22, 22, 'absent', NULL),
(
    23,
    22,
    'present',
    '2026-02-02 11:06:00+01:00'
),
(
    24,
    22,
    'present',
    '2026-02-02 11:03:00+01:00'
),
(
    25,
    22,
    'late',
    '2026-02-02 11:28:00+01:00'
),
(
    26,
    22,
    'present',
    '2026-02-02 11:05:00+01:00'
),
(
    27,
    22,
    'present',
    '2026-02-02 11:02:00+01:00'
),
(
    28,
    22,
    'present',
    '2026-02-02 11:07:00+01:00'
),
(29, 22, 'absent', NULL),
(
    30,
    22,
    'present',
    '2026-02-02 11:04:00+01:00'
),
(
    31,
    22,
    'present',
    '2026-02-02 11:06:00+01:00'
),
(
    32,
    22,
    'present',
    '2026-02-02 11:03:00+01:00'
),
(
    33,
    22,
    'late',
    '2026-02-02 11:30:00+01:00'
),
(
    34,
    22,
    'present',
    '2026-02-02 11:05:00+01:00'
),

-- NS102 Class 3
(
    20,
    23,
    'present',
    '2026-02-03 11:03:00+01:00'
),
(
    21,
    23,
    'late',
    '2026-02-03 11:27:00+01:00'
),
(
    22,
    23,
    'present',
    '2026-02-03 11:05:00+01:00'
),
(
    23,
    23,
    'present',
    '2026-02-03 11:04:00+01:00'
),
(
    24,
    23,
    'present',
    '2026-02-03 11:06:00+01:00'
),
(25, 23, 'absent', NULL),
(
    26,
    23,
    'present',
    '2026-02-03 11:03:00+01:00'
),
(
    27,
    23,
    'present',
    '2026-02-03 11:07:00+01:00'
),
(
    28,
    23,
    'present',
    '2026-02-03 11:02:00+01:00'
),
(29, 23, 'absent', NULL),
(
    30,
    23,
    'late',
    '2026-02-03 11:29:00+01:00'
),
(
    31,
    23,
    'present',
    '2026-02-03 11:04:00+01:00'
),
(
    32,
    23,
    'present',
    '2026-02-03 11:05:00+01:00'
),
(
    33,
    23,
    'present',
    '2026-02-03 11:03:00+01:00'
),
(
    34,
    23,
    'present',
    '2026-02-03 11:06:00+01:00'
),

-- NS103 Class 1
(
    20,
    26,
    'present',
    '2026-02-01 14:04:00+01:00'
),
(
    21,
    26,
    'present',
    '2026-02-01 14:06:00+01:00'
),
(
    22,
    26,
    'late',
    '2026-02-01 14:28:00+01:00'
),
(
    23,
    26,
    'present',
    '2026-02-01 14:03:00+01:00'
),
(24, 26, 'absent', NULL),
(
    25,
    26,
    'present',
    '2026-02-01 14:05:00+01:00'
),
(
    26,
    26,
    'present',
    '2026-02-01 14:02:00+01:00'
),
(
    27,
    26,
    'present',
    '2026-02-01 14:07:00+01:00'
),
(
    28,
    26,
    'present',
    '2026-02-01 14:04:00+01:00'
),
(29, 26, 'absent', NULL),
(
    30,
    26,
    'present',
    '2026-02-01 14:06:00+01:00'
),
(
    31,
    26,
    'late',
    '2026-02-01 14:31:00+01:00'
),
(
    32,
    26,
    'present',
    '2026-02-01 14:03:00+01:00'
),
(
    33,
    26,
    'present',
    '2026-02-01 14:05:00+01:00'
),
(
    34,
    26,
    'present',
    '2026-02-01 14:02:00+01:00'
),

-- NS103 Class 2
(
    20,
    27,
    'present',
    '2026-02-02 14:05:00+01:00'
),
(21, 27, 'absent', NULL),
(
    22,
    27,
    'present',
    '2026-02-02 14:04:00+01:00'
),
(
    23,
    27,
    'present',
    '2026-02-02 14:06:00+01:00'
),
(
    24,
    27,
    'late',
    '2026-02-02 14:27:00+01:00'
),
(
    25,
    27,
    'present',
    '2026-02-02 14:03:00+01:00'
),
(
    26,
    27,
    'present',
    '2026-02-02 14:05:00+01:00'
),
(
    27,
    27,
    'present',
    '2026-02-02 14:02:00+01:00'
),
(
    28,
    27,
    'present',
    '2026-02-02 14:07:00+01:00'
),
(29, 27, 'absent', NULL),
(
    30,
    27,
    'present',
    '2026-02-02 14:04:00+01:00'
),
(
    31,
    27,
    'present',
    '2026-02-02 14:06:00+01:00'
),
(
    32,
    27,
    'late',
    '2026-02-02 14:32:00+01:00'
),
(
    33,
    27,
    'present',
    '2026-02-02 14:03:00+01:00'
),
(
    34,
    27,
    'present',
    '2026-02-02 14:05:00+01:00'
),

-- NS103 Class 3
(
    20,
    28,
    'present',
    '2026-02-03 14:03:00+01:00'
),
(
    21,
    28,
    'present',
    '2026-02-03 14:05:00+01:00'
),
(
    22,
    28,
    'present',
    '2026-02-03 14:04:00+01:00'
),
(23, 28, 'absent', NULL),
(
    24,
    28,
    'present',
    '2026-02-03 14:06:00+01:00'
),
(
    25,
    28,
    'late',
    '2026-02-03 14:30:00+01:00'
),
(
    26,
    28,
    'present',
    '2026-02-03 14:02:00+01:00'
),
(
    27,
    28,
    'present',
    '2026-02-03 14:07:00+01:00'
),
(28, 28, 'absent', NULL),
(
    29,
    28,
    'present',
    '2026-02-03 14:05:00+01:00'
),
(
    30,
    28,
    'present',
    '2026-02-03 14:03:00+01:00'
),
(
    31,
    28,
    'present',
    '2026-02-03 14:04:00+01:00'
),
(
    32,
    28,
    'late',
    '2026-02-03 14:29:00+01:00'
),
(
    33,
    28,
    'present',
    '2026-02-03 14:06:00+01:00'
),
(
    34,
    28,
    'present',
    '2026-02-03 14:02:00+01:00'
),

-- Information Systems Management - Random attendance
\echo '        ✓ NS attendance data complete'
\echo '        Generating attendance records for Information Systems Management department...'
-- ISM101 Class 1
(
    35,
    31,
    'present',
    '2026-02-01 09:04:00+01:00'
),
(
    36,
    31,
    'present',
    '2026-02-01 09:06:00+01:00'
),
(
    37,
    31,
    'late',
    '2026-02-01 09:27:00+01:00'
),
(
    38,
    31,
    'present',
    '2026-02-01 09:03:00+01:00'
),
(39, 31, 'absent', NULL),
(
    40,
    31,
    'present',
    '2026-02-01 09:05:00+01:00'
),
(
    41,
    31,
    'present',
    '2026-02-01 09:02:00+01:00'
),
(
    42,
    31,
    'present',
    '2026-02-01 09:07:00+01:00'
),
(43, 31, 'absent', NULL),
(
    44,
    31,
    'present',
    '2026-02-01 09:04:00+01:00'
),
(
    45,
    31,
    'late',
    '2026-02-01 09:33:00+01:00'
),
(
    46,
    31,
    'present',
    '2026-02-01 09:05:00+01:00'
),
(
    47,
    31,
    'present',
    '2026-02-01 09:03:00+01:00'
),
(
    48,
    31,
    'present',
    '2026-02-01 09:06:00+01:00'
),
(
    49,
    31,
    'present',
    '2026-02-01 09:02:00+01:00'
),

-- ISM101 Class 2
(
    35,
    32,
    'present',
    '2026-02-02 09:05:00+01:00'
),
(
    36,
    32,
    'present',
    '2026-02-02 09:03:00+01:00'
),
(
    37,
    32,
    'present',
    '2026-02-02 09:06:00+01:00'
),
(38, 32, 'absent', NULL),
(
    39,
    32,
    'late',
    '2026-02-02 09:28:00+01:00'
),
(
    40,
    32,
    'present',
    '2026-02-02 09:04:00+01:00'
),
(
    41,
    32,
    'present',
    '2026-02-02 09:07:00+01:00'
),
(
    42,
    32,
    'present',
    '2026-02-02 09:02:00+01:00'
),
(
    43,
    32,
    'present',
    '2026-02-02 09:05:00+01:00'
),
(44, 32, 'absent', NULL),
(
    45,
    32,
    'present',
    '2026-02-02 09:06:00+01:00'
),
(
    46,
    32,
    'present',
    '2026-02-02 09:03:00+01:00'
),
(
    47,
    32,
    'late',
    '2026-02-02 09:30:00+01:00'
),
(
    48,
    32,
    'present',
    '2026-02-02 09:04:00+01:00'
),
(
    49,
    32,
    'present',
    '2026-02-02 09:07:00+01:00'
),

-- ISM101 Class 3
(
    35,
    33,
    'present',
    '2026-02-03 09:03:00+01:00'
),
(
    36,
    33,
    'late',
    '2026-02-03 09:26:00+01:00'
),
(
    37,
    33,
    'present',
    '2026-02-03 09:05:00+01:00'
),
(
    38,
    33,
    'present',
    '2026-02-03 09:04:00+01:00'
),
(39, 33, 'absent', NULL),
(
    40,
    33,
    'present',
    '2026-02-03 09:06:00+01:00'
),
(
    41,
    33,
    'present',
    '2026-02-03 09:02:00+01:00'
),
(42, 33, 'absent', NULL),
(
    43,
    33,
    'present',
    '2026-02-03 09:07:00+01:00'
),
(
    44,
    33,
    'present',
    '2026-02-03 09:03:00+01:00'
),
(
    45,
    33,
    'late',
    '2026-02-03 09:29:00+01:00'
),
(
    46,
    33,
    'present',
    '2026-02-03 09:04:00+01:00'
),
(
    47,
    33,
    'present',
    '2026-02-03 09:05:00+01:00'
),
(
    48,
    33,
    'present',
    '2026-02-03 09:06:00+01:00'
),
(
    49,
    33,
    'present',
    '2026-02-03 09:02:00+01:00'
),

-- ISM102 Class 1
(
    35,
    36,
    'present',
    '2026-02-01 11:04:00+01:00'
),
(
    36,
    36,
    'present',
    '2026-02-01 11:06:00+01:00'
),
(
    37,
    36,
    'present',
    '2026-02-01 11:03:00+01:00'
),
(
    38,
    36,
    'present',
    '2026-02-01 11:05:00+01:00'
),
(
    39,
    36,
    'late',
    '2026-02-01 11:31:00+01:00'
),
(40, 36, 'absent', NULL),
(
    41,
    36,
    'present',
    '2026-02-01 11:02:00+01:00'
),
(
    42,
    36,
    'present',
    '2026-02-01 11:07:00+01:00'
),
(
    43,
    36,
    'present',
    '2026-02-01 11:04:00+01:00'
),
(
    44,
    36,
    'present',
    '2026-02-01 11:03:00+01:00'
),
(45, 36, 'absent', NULL),
(
    46,
    36,
    'late',
    '2026-02-01 11:34:00+01:00'
),
(
    47,
    36,
    'present',
    '2026-02-01 11:05:00+01:00'
),
(
    48,
    36,
    'present',
    '2026-02-01 11:02:00+01:00'
),
(
    49,
    36,
    'present',
    '2026-02-01 11:06:00+01:00'
),

-- ISM102 Class 2
(
    35,
    37,
    'present',
    '2026-02-02 11:05:00+01:00'
),
(36, 37, 'absent', NULL),
(
    37,
    37,
    'present',
    '2026-02-02 11:04:00+01:00'
),
(
    38,
    37,
    'present',
    '2026-02-02 11:06:00+01:00'
),
(
    39,
    37,
    'present',
    '2026-02-02 11:03:00+01:00'
),
(
    40,
    37,
    'late',
    '2026-02-02 11:29:00+01:00'
),
(
    41,
    37,
    'present',
    '2026-02-02 11:05:00+01:00'
),
(
    42,
    37,
    'present',
    '2026-02-02 11:02:00+01:00'
),
(
    43,
    37,
    'present',
    '2026-02-02 11:07:00+01:00'
),
(44, 37, 'absent', NULL),
(
    45,
    37,
    'present',
    '2026-02-02 11:04:00+01:00'
),
(
    46,
    37,
    'present',
    '2026-02-02 11:06:00+01:00'
),
(
    47,
    37,
    'late',
    '2026-02-02 11:32:00+01:00'
),
(
    48,
    37,
    'present',
    '2026-02-02 11:03:00+01:00'
),
(
    49,
    37,
    'present',
    '2026-02-02 11:05:00+01:00'
),

-- ISM102 Class 3
(
    35,
    38,
    'present',
    '2026-02-03 11:03:00+01:00'
),
(
    36,
    38,
    'present',
    '2026-02-03 11:05:00+01:00'
),
(37, 38, 'absent', NULL),
(
    38,
    38,
    'late',
    '2026-02-03 11:28:00+01:00'
),
(
    39,
    38,
    'present',
    '2026-02-03 11:04:00+01:00'
),
(
    40,
    38,
    'present',
    '2026-02-03 11:06:00+01:00'
),
(
    41,
    38,
    'present',
    '2026-02-03 11:02:00+01:00'
),
(
    42,
    38,
    'present',
    '2026-02-03 11:07:00+01:00'
),
(
    43,
    38,
    'present',
    '2026-02-03 11:03:00+01:00'
),
(44, 38, 'absent', NULL),
(
    45,
    38,
    'late',
    '2026-02-03 11:30:00+01:00'
),
(
    46,
    38,
    'present',
    '2026-02-03 11:04:00+01:00'
),
(
    47,
    38,
    'present',
    '2026-02-03 11:05:00+01:00'
),
(
    48,
    38,
    'present',
    '2026-02-03 11:06:00+01:00'
),
(
    49,
    38,
    'present',
    '2026-02-03 11:02:00+01:00'
),

-- ISM103 Class 1
(
    35,
    41,
    'present',
    '2026-02-01 14:05:00+01:00'
),
(
    36,
    41,
    'present',
    '2026-02-01 14:04:00+01:00'
),
(
    37,
    41,
    'late',
    '2026-02-01 14:29:00+01:00'
),
(
    38,
    41,
    'present',
    '2026-02-01 14:03:00+01:00'
),
(
    39,
    41,
    'present',
    '2026-02-01 14:06:00+01:00'
),
(40, 41, 'absent', NULL),
(
    41,
    41,
    'present',
    '2026-02-01 14:02:00+01:00'
),
(
    42,
    41,
    'present',
    '2026-02-01 14:07:00+01:00'
),
(
    43,
    41,
    'present',
    '2026-02-01 14:04:00+01:00'
),
(44, 41, 'absent', NULL),
(
    45,
    41,
    'late',
    '2026-02-01 14:32:00+01:00'
),
(
    46,
    41,
    'present',
    '2026-02-01 14:05:00+01:00'
),
(
    47,
    41,
    'present',
    '2026-02-01 14:03:00+01:00'
),
(
    48,
    41,
    'present',
    '2026-02-01 14:06:00+01:00'
),
(
    49,
    41,
    'present',
    '2026-02-01 14:02:00+01:00'
),

-- ISM103 Class 2
(
    35,
    42,
    'present',
    '2026-02-02 14:04:00+01:00'
),
(
    36,
    42,
    'present',
    '2026-02-02 14:06:00+01:00'
),
(
    37,
    42,
    'present',
    '2026-02-02 14:03:00+01:00'
),
(38, 42, 'absent', NULL),
(
    39,
    42,
    'late',
    '2026-02-02 14:27:00+01:00'
),
(
    40,
    42,
    'present',
    '2026-02-02 14:05:00+01:00'
),
(
    41,
    42,
    'present',
    '2026-02-02 14:02:00+01:00'
),
(
    42,
    42,
    'present',
    '2026-02-02 14:07:00+01:00'
),
(
    43,
    42,
    'present',
    '2026-02-02 14:04:00+01:00'
),
(44, 42, 'absent', NULL),
(
    45,
    42,
    'present',
    '2026-02-02 14:06:00+01:00'
),
(
    46,
    42,
    'present',
    '2026-02-02 14:03:00+01:00'
),
(
    47,
    42,
    'late',
    '2026-02-02 14:31:00+01:00'
),
(
    48,
    42,
    'present',
    '2026-02-02 14:05:00+01:00'
),
(
    49,
    42,
    'present',
    '2026-02-02 14:02:00+01:00'
),

-- ISM103 Class 3
(
    35,
    43,
    'present',
    '2026-02-03 14:03:00+01:00'
),
(
    36,
    43,
    'late',
    '2026-02-03 14:26:00+01:00'
),
(
    37,
    43,
    'present',
    '2026-02-03 14:05:00+01:00'
),
(
    38,
    43,
    'present',
    '2026-02-03 14:04:00+01:00'
),
(39, 43, 'absent', NULL),
(
    40,
    43,
    'present',
    '2026-02-03 14:06:00+01:00'
),
(
    41,
    43,
    'present',
    '2026-02-03 14:02:00+01:00'
),
(
    42,
    43,
    'present',
    '2026-02-03 14:07:00+01:00'
),
(43, 43, 'absent', NULL),
(
    44,
    43,
    'present',
    '2026-02-03 14:03:00+01:00'
),
(
    45,
    43,
    'late',
    '2026-02-03 14:28:00+01:00'
),
(
    46,
    43,
    'present',
    '2026-02-03 14:04:00+01:00'
),
(
    47,
    43,
    'present',
    '2026-02-03 14:05:00+01:00'
),
(
    48,
    43,
    'present',
    '2026-02-03 14:06:00+01:00'
),
(
    49,
    43,
    'present',
    '2026-02-03 14:02:00+01:00'
);

\echo ' ✓ ISM attendance data complete' \echo ''