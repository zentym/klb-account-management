package com.kienlongbank.notification_service.listener;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

@Component
@Slf4j // Annotation của Lombok để tự tạo một đối tượng log
public class NotificationListener {

    /**
     * Phương thức này sẽ tự động được gọi mỗi khi có tin nhắn mới
     * trong queue có tên được định nghĩa trong application.properties.
     */
    @RabbitListener(queues = "${notification.queue.name}")
    public void handleNotification(String message) {
        log.info("=> Received a new notification: '{}'", message);

        // TODO: Trong tương lai, bạn sẽ thêm logic xử lý chi tiết ở đây.
        // Ví dụ:
        // 1. Phân tích nội dung message (JSON) để biết đây là thông báo gì.
        // 2. Gọi đến dịch vụ gửi Email hoặc SMS để gửi đi thông báo thực tế.
        System.out.println("LOG: Sending notification for message: " + message);
    }
}