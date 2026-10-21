package com.tuowei.dazhongdianping.module.trade.service;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.WriterException;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.qrcode.QRCodeWriter;
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Base64;
import java.util.Map;

/** Renders inside the application; redeemable codes must never reach a QR image provider. */
final class CouponQrCodeRenderer {
    private CouponQrCodeRenderer() {}

    static String pngDataUrl(String code) {
        if (code == null || code.isBlank()) return "";
        try {
            var matrix = new QRCodeWriter().encode(code, BarcodeFormat.QR_CODE, 240, 240,
                    Map.of(EncodeHintType.MARGIN, 4,
                            EncodeHintType.ERROR_CORRECTION, ErrorCorrectionLevel.M));
            var output = new ByteArrayOutputStream();
            MatrixToImageWriter.writeToStream(matrix, "PNG", output);
            return "data:image/png;base64," + Base64.getEncoder().encodeToString(output.toByteArray());
        } catch (WriterException | IOException exception) {
            throw new IllegalStateException("Could not render coupon QR code", exception);
        }
    }
}
