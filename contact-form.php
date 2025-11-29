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
    // Collect and sanitize form data
    $full_name = htmlspecialchars(trim($_POST['full_name']));
    $phone = htmlspecialchars(trim($_POST['phone']));
    $email = filter_var(trim($_POST['email']), FILTER_SANITIZE_EMAIL);
    $subject = htmlspecialchars(trim($_POST['subject']));
    $message = htmlspecialchars(trim($_POST['message']));
    
    // Basic validation
    if (empty($full_name) || empty($phone) || empty($email) || empty($subject) || empty($message)) {
        header('Content-Type: application/json');
        echo json_encode([
            'success' => false,
            'message' => 'All required fields must be filled.'
        ]);
        exit;
    }
    
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        header('Content-Type: application/json');
        echo json_encode([
            'success' => false,
            'message' => 'Please enter a valid email address.'
        ]);
        exit;
    }
    
    try {
        // Insert into database
        $sql = "INSERT INTO contact_messages (
            full_name, phone, email, subject, message, created_at
        ) VALUES (?, ?, ?, ?, ?, NOW())";
        
        $stmt = $conn->prepare($sql);
        $stmt->execute([$full_name, $phone, $email, $subject, $message]);
        
        $message_id = $conn->lastInsertId();
        
        // Prepare email content
        $to = "lk2017015453@gmail.com"; // Admin email
        $email_subject = "New Contact Form Submission: $subject";
        
        $email_message = "
        <html>
        <head>
            <title>New Contact Form Submission</title>
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
                    <h1>New Contact Form Submission</h1>
                </div>
                <div class='content'>
                    <div class='field'><span class='field-label'>Full Name:</span> $full_name</div>
                    <div class='field'><span class='field-label'>Phone:</span> $phone</div>
                    <div class='field'><span class='field-label'>Email:</span> $email</div>
                    <div class='field'><span class='field-label'>Subject:</span> $subject</div>
                    <div class='field'><span class='field-label'>Message:</span> $message</div>
                    <div class='field'><span class='field-label'>Submission Date:</span> " . date('Y-m-d H:i:s') . "</div>
                    <div class='field'><span class='field-label'>Message ID:</span> $message_id</div>
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
        $mail_sent = mail($to, $email_subject, $email_message, $headers);
        
        // Return success response
        header('Content-Type: application/json');
        echo json_encode([
            'success' => true,
            'message' => 'Message sent successfully'
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