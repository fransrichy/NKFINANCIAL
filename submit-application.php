<?php
// Database configuration
$servername = "localhost";
$username = "your_username"; // Change to your MySQL username
$password = "your_password"; // Change to your MySQL password
$dbname = "nanghali_loans";

// Create connection
try {
    $conn = new PDO("mysql:host=$servername;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ATTR_ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    header('Content-Type: application/json');
    echo json_encode([
        'success' => false,
        'message' => 'Database connection failed: ' . $e->getMessage()
    ]);
    exit;
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Validate security question
    $security_answer = $_POST['security_answer'] ?? '';
    if (intval($security_answer) !== 8) {
        header('Content-Type: application/json');
        echo json_encode([
            'success' => false,
            'message' => 'Security question answer is incorrect.'
        ]);
        exit;
    }

    // Collect and sanitize form data
    $full_name = htmlspecialchars(trim($_POST['full_name']));
    $id_number = htmlspecialchars(trim($_POST['id_number']));
    $phone = htmlspecialchars(trim($_POST['phone']));
    $email = filter_var(trim($_POST['email']), FILTER_SANITIZE_EMAIL);
    $address = htmlspecialchars(trim($_POST['address']));
    $employment = htmlspecialchars(trim($_POST['employment']));
    $income = floatval($_POST['income']);
    $loan_amount = floatval($_POST['loan_amount']);
    $loan_type = htmlspecialchars(trim($_POST['loan_type']));
    $loan_reason = htmlspecialchars(trim($_POST['loan_reason'] ?? ''));
    
    // Basic validation
    if (empty($full_name) || empty($id_number) || empty($phone) || empty($email) || empty($address)) {
        header('Content-Type: application/json');
        echo json_encode([
            'success' => false,
            'message' => 'All required fields must be filled.'
        ]);
        exit;
    }

    // File upload handling
    $upload_dir = "uploads/";
    if (!file_exists($upload_dir)) {
        mkdir($upload_dir, 0777, true);
    }
    
    $uploaded_files = [];
    $file_errors = [];
    
    // Process each file upload
    $file_fields = [
        'id_copy' => 'ID Copy',
        'payslip' => 'Payslip', 
        'bank_statement' => 'Bank Statement'
    ];
    
    foreach ($file_fields as $field => $field_name) {
        if (isset($_FILES[$field]) && $_FILES[$field]['error'] === UPLOAD_ERR_OK) {
            $file_name = time() . '_' . preg_replace("/[^a-zA-Z0-9\.]/", "_", $_FILES[$field]['name']);
            $target_path = $upload_dir . $file_name;
            
            // Check file type
            $allowed_types = ['pdf', 'jpg', 'jpeg', 'png'];
            $file_extension = strtolower(pathinfo($target_path, PATHINFO_EXTENSION));
            
            if (in_array($file_extension, $allowed_types)) {
                // Check file size (5MB max)
                if ($_FILES[$field]['size'] <= 5 * 1024 * 1024) {
                    if (move_uploaded_file($_FILES[$field]['tmp_name'], $target_path)) {
                        $uploaded_files[$field] = $target_path;
                    } else {
                        $file_errors[] = "Failed to upload $field_name";
                    }
                } else {
                    $file_errors[] = "$field_name is too large (max 5MB)";
                }
            } else {
                $file_errors[] = "$field_name must be PDF, JPG, or PNG";
            }
        } else {
            $file_errors[] = "$field_name is required";
        }
    }
    
    // Process additional documents (optional)
    if (isset($_FILES['additional_docs']) && $_FILES['additional_docs']['error'] === UPLOAD_ERR_OK) {
        $file_name = time() . '_' . preg_replace("/[^a-zA-Z0-9\.]/", "_", $_FILES['additional_docs']['name']);
        $target_path = $upload_dir . $file_name;
        
        $allowed_types = ['pdf', 'jpg', 'jpeg', 'png'];
        $file_extension = strtolower(pathinfo($target_path, PATHINFO_EXTENSION));
        
        if (in_array($file_extension, $allowed_types) && $_FILES['additional_docs']['size'] <= 5 * 1024 * 1024) {
            if (move_uploaded_file($_FILES['additional_docs']['tmp_name'], $target_path)) {
                $uploaded_files['additional_docs'] = $target_path;
            }
        }
    }
    
    // If there are file errors, return them
    if (!empty($file_errors)) {
        header('Content-Type: application/json');
        echo json_encode([
            'success' => false,
            'message' => 'File upload errors: ' . implode(', ', $file_errors)
        ]);
        exit;
    }
    
    // Generate reference number
    $reference_number = 'NYL-' . date('Y') . '-' . str_pad(rand(1, 999999), 6, '0', STR_PAD_LEFT);
    
    try {
        // Insert into database
        $sql = "INSERT INTO loan_applications (
            reference_number, full_name, id_number, phone, email, address, 
            employment_status, monthly_income, loan_amount, loan_type, loan_reason,
            id_copy_path, payslip_path, bank_statement_path, additional_docs_path
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        $stmt = $conn->prepare($sql);
        $stmt->execute([
            $reference_number, $full_name, $id_number, $phone, $email, $address,
            $employment, $income, $loan_amount, $loan_type, $loan_reason,
            $uploaded_files['id_copy'] ?? null,
            $uploaded_files['payslip'] ?? null,
            $uploaded_files['bank_statement'] ?? null,
            $uploaded_files['additional_docs'] ?? null
        ]);
        
        $application_id = $conn->lastInsertId();
        
        // Prepare email content
        $to = "lk2017015453@gmail.com"; // Admin email
        $subject = "New Loan Application - $reference_number";
        
        $message = "
        <html>
        <head>
            <title>New Loan Application</title>
            <style>
                body { font-family: Arial, sans-serif; }
                .container { max-width: 600px; margin: 0 auto; padding: 20px; }
                .header { background: #1a5276; color: white; padding: 20px; text-align: center; }
                .content { padding: 20px; background: #f9f9f9; }
                .field { margin-bottom: 10px; }
                .field-label { font-weight: bold; color: #1a5276; }
            </style>
        </head>
        <body>
            <div class='container'>
                <div class='header'>
                    <h1>New Loan Application Received</h1>
                </div>
                <div class='content'>
                    <div class='field'><span class='field-label'>Reference Number:</span> $reference_number</div>
                    <div class='field'><span class='field-label'>Full Name:</span> $full_name</div>
                    <div class='field'><span class='field-label'>ID/Passport Number:</span> $id_number</div>
                    <div class='field'><span class='field-label'>Phone:</span> $phone</div>
                    <div class='field'><span class='field-label'>Email:</span> $email</div>
                    <div class='field'><span class='field-label'>Address:</span> $address</div>
                    <div class='field'><span class='field-label'>Employment Status:</span> $employment</div>
                    <div class='field'><span class='field-label'>Monthly Income:</span> N$ $income</div>
                    <div class='field'><span class='field-label'>Loan Amount Requested:</span> N$ $loan_amount</div>
                    <div class='field'><span class='field-label'>Loan Type:</span> $loan_type</div>
                    <div class='field'><span class='field-label'>Reason for Loan:</span> $loan_reason</div>
                    <div class='field'><span class='field-label'>Application Date:</span> " . date('Y-m-d H:i:s') . "</div>
                    <div class='field'><span class='field-label'>Application ID:</span> $application_id</div>
                </div>
            </div>
        </body>
        </html>
        ";
        
        // Email headers
        $headers = "MIME-Version: 1.0" . "\r\n";
        $headers .= "Content-type:text/html;charset=UTF-8" . "\r\n";
        $headers .= "From: noreply@nanghaliyakafita.com" . "\r\n";
        $headers .= "Reply-To: $email" . "\r\n";
        
        // Send email to admin
        $mail_sent = mail($to, $subject, $message, $headers);
        
        // Send confirmation email to applicant (optional)
        $applicant_subject = "Loan Application Received - $reference_number";
        $applicant_message = "
        <html>
        <head>
            <title>Application Confirmation</title>
        </head>
        <body>
            <h2>Thank you for your loan application!</h2>
            <p>Dear $full_name,</p>
            <p>We have received your loan application with reference number: <strong>$reference_number</strong></p>
            <p>Our team will review your application and contact you within 24-48 hours.</p>
            <p>If you have any questions, please contact us at +264 81 864 4104 or reply to this email.</p>
            <br>
            <p>Best regards,<br>NANGHALI YA KAFITA Financial Services CC</p>
        </body>
        </html>
        ";
        
        $applicant_headers = "MIME-Version: 1.0" . "\r\n";
        $applicant_headers .= "Content-type:text/html;charset=UTF-8" . "\r\n";
        $applicant_headers .= "From: noreply@nanghaliyakafita.com" . "\r\n";
        
        mail($email, $applicant_subject, $applicant_message, $applicant_headers);
        
        // Return success response
        header('Content-Type: application/json');
        echo json_encode([
            'success' => true,
            'reference_number' => $reference_number,
            'application_id' => $application_id,
            'message' => 'Application submitted successfully'
        ]);
        
    } catch(PDOException $e) {
        // Database error
        header('Content-Type: application/json');
        echo json_encode([
            'success' => false,
            'message' => 'Database error: ' . $e->getMessage()
        ]);
    }
    
} else {
    // Invalid request method
    header('Content-Type: application/json');
    echo json_encode([
        'success' => false,
        'message' => 'Invalid request method'
    ]);
}
?>