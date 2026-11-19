package com.example.MotvirsWeb.infraestructura.correo;

import org.junit.jupiter.api.Test;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.MailSendException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;

class EmailServiceAvisoDeudaTest {
    @Test
    void falloSmtpSePropagaParaReintento() {
        EmailService correo = new EmailService();
        JavaMailSender smtp = mock(JavaMailSender.class);
        ReflectionTestUtils.setField(correo, "mailSender", smtp);
        ReflectionTestUtils.setField(correo, "myEmail", "nexa@example.test");
        doThrow(new MailSendException("fallo sintético")).when(smtp).send(any(SimpleMailMessage.class));

        assertThrows(MailSendException.class,
                () -> correo.enviarDeudaSeCobraEnProximoViaje("usuario@example.test", "Prueba", 4000));
    }
}
