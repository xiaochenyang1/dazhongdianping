package com.tuowei.dazhongdianping.module.invoice.service;

import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.admin.rbac.service.AdminAuditLogService;
import com.tuowei.dazhongdianping.module.auth.mapper.AuthCommandMapper;
import com.tuowei.dazhongdianping.module.invoice.mapper.InvoiceDocumentMapper;
import com.tuowei.dazhongdianping.module.invoice.mapper.InvoiceMapper;
import com.tuowei.dazhongdianping.module.invoice.model.InvoiceDocumentRow;
import com.tuowei.dazhongdianping.module.invoice.model.InvoiceRequestRow;
import java.io.IOException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Map;
import org.apache.pdfbox.io.RandomAccessReadBuffer;
import org.apache.pdfbox.pdfparser.PDFParser;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.springframework.http.CacheControl;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

@Service
public class InvoiceDocumentService {
    public static final int MAX_BYTES = 5 * 1024 * 1024;
    private final InvoiceMapper invoices;
    private final InvoiceDocumentMapper documents;
    private final AuthCommandMapper accounts;
    private final AdminAuditLogService audit;

    public InvoiceDocumentService(InvoiceMapper invoices, InvoiceDocumentMapper documents,
                                  AuthCommandMapper accounts, AdminAuditLogService audit) {
        this.invoices = invoices;
        this.documents = documents;
        this.accounts = accounts;
        this.audit = audit;
    }

    @Transactional
    public Map<String, Object> upload(Long id, String invoiceNo, MultipartFile file, String ip) {
        var admin = AdminSessionContext.get();
        if (admin == null) throw new UnauthorizedException("管理员登录状态不存在");
        String number = invoiceNo == null ? "" : invoiceNo.trim();
        if (number.isEmpty() || number.length() > 64) throw new IllegalArgumentException("请填写有效的发票号");
        InvoiceRequestRow row = scopedRequest(id, false);
        // Same account lock order as export/deletion: a deleted owner's PDF cannot be resurrected.
        lockActiveOwner(row.getUserId());
        row = invoices.lockRequest(id, region());
        if (row.getStatus() != 1 && row.getStatus() != 2) throw new ConflictException("当前申请不可交付发票");
        if (row.getStatus() == 2 && !number.equals(row.getInvoiceNo())) {
            throw new ConflictException("发票号与已登记号码不一致");
        }
        byte[] bytes = validatePdf(file);
        String hash = sha256(bytes);
        InvoiceDocumentRow existing = documents.selectDocument(id);
        if (existing != null) {
            if (!hash.equals(existing.getSha256())) throw new ConflictException("发票文件已交付，不可覆盖");
            return InvoiceProjection.request(invoices.selectCurrentRequest(id, region()));
        }
        InvoiceDocumentRow doc = new InvoiceDocumentRow();
        doc.setInvoiceId(id);
        doc.setContent(bytes);
        doc.setSha256(hash);
        doc.setSizeBytes(bytes.length);
        doc.setUploadedBy(admin.adminId());
        documents.insertDocument(doc);
        if (row.getStatus() == 1 && invoices.issue(id, region(), number) != 1) {
            throw new ConflictException("开票申请当前状态不可开具");
        }
        audit.record(admin.adminId(), "invoice.document.publish", "invoice:" + id, "sha256=" + hash, ip);
        return InvoiceProjection.request(invoices.selectCurrentRequest(id, region()));
    }

    @Transactional
    public ResponseEntity<byte[]> download(Long id, boolean customer, String ip) {
        InvoiceRequestRow row = scopedRequest(id, customer);
        lockActiveOwner(row.getUserId());
        InvoiceDocumentRow doc = documents.selectDocument(id);
        if (doc == null) throw new NotFoundException("发票文件尚未交付");
        if (!customer) {
            audit.record(AdminSessionContext.get().adminId(), "invoice.document.download", "invoice:" + id, "", ip);
        }
        return ResponseEntity.ok().contentType(MediaType.APPLICATION_PDF)
                .contentLength(doc.getSizeBytes()).cacheControl(CacheControl.noStore())
                .header("X-Content-Type-Options", "nosniff")
                .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.attachment().filename(doc.getFileName()).build().toString())
                .body(doc.getContent());
    }

    @Transactional
    public Map<String, Object> confirmReceipt(Long id, String hash) {
        InvoiceRequestRow row = scopedRequest(id, true);
        lockActiveOwner(row.getUserId());
        invoices.lockRequest(id, region());
        InvoiceDocumentRow doc = documents.selectDocument(id);
        if (doc == null) throw new NotFoundException("发票文件尚未交付");
        if (!hash.equals(doc.getSha256())) throw new ConflictException("发票文件已变化，请刷新后确认");
        documents.confirmReceipt(id, hash);
        return InvoiceProjection.request(invoices.selectCurrentRequest(id, region()));
    }

    private InvoiceRequestRow scopedRequest(Long id, boolean customer) {
        Long userId = null;
        if (customer) {
            var user = UserSessionContext.get();
            if (user == null) throw new UnauthorizedException("用户登录状态不存在");
            userId = user.userId();
        } else if (AdminSessionContext.get() == null) {
            throw new UnauthorizedException("管理员登录状态不存在");
        }
        InvoiceRequestRow row = invoices.selectRequest(id, region());
        if (row == null || (customer && !row.getUserId().equals(userId))) throw new NotFoundException("开票申请不存在");
        return row;
    }

    private void lockActiveOwner(Long userId) {
        var user = accounts.selectUserByIdForUpdate(userId);
        if (user == null || user.getStatus() == null || user.getStatus() != 1) {
            throw new ConflictException("账户已停用，无法交付发票");
        }
    }

    private byte[] validatePdf(MultipartFile file) {
        if (file == null || file.isEmpty() || file.getSize() > MAX_BYTES) {
            throw new IllegalArgumentException("请上传不超过 5 MB 的有效 PDF 发票");
        }
        try {
            byte[] bytes;
            try (var input = file.getInputStream()) { bytes = input.readNBytes(MAX_BYTES + 1); }
            if (bytes.length > MAX_BYTES || bytes.length < 5 || bytes[0] != '%' || bytes[1] != 'P'
                    || bytes[2] != 'D' || bytes[3] != 'F' || bytes[4] != '-') {
                throw new IllegalArgumentException("请上传不超过 5 MB 的有效 PDF 发票");
            }
            try (var source = new RandomAccessReadBuffer(bytes)) {
                PDFParser parser = new PDFParser(source);
                try (PDDocument pdf = parser.parse(false)) {
                    if (pdf.isEncrypted() || pdf.getNumberOfPages() < 1) {
                        throw new IllegalArgumentException("发票 PDF 不可加密且必须包含页面");
                    }
                }
            }
            return bytes;
        } catch (IOException exception) {
            throw new IllegalArgumentException("无法读取 PDF，请上传未加密的有效发票");
        }
    }

    private String sha256(byte[] bytes) {
        try { return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes)); }
        catch (NoSuchAlgorithmException exception) { throw new IllegalStateException(exception); }
    }

    private String region() { return RegionContext.getRegion().name(); }
}
