package com.tuowei.dazhongdianping.module.auth.service;

import com.tuowei.dazhongdianping.module.auth.mapper.UserPrivacyDomainMapper;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserPrivacyDomainService {
    private final UserPrivacyDomainMapper mapper;

    public UserPrivacyDomainService(UserPrivacyDomainMapper mapper) {
        this.mapper = mapper;
    }

    public Object exportModule(String module, Long userId) {
        return switch (module) {
            case "invoices" -> Map.of("titles", mapper.selectInvoiceTitles(userId), "requests", mapper.selectInvoices(userId));
            case "tickets" -> Map.of("tickets", mapper.selectTickets(userId), "messages", mapper.selectTicketMessages(userId));
            case "consult" -> Map.of("sessions", mapper.selectConsultSessions(userId), "messages", mapper.selectConsultMessages(userId));
            case "waitlist" -> mapper.selectWaitlist(userId);
            case "translations" -> mapper.selectTranslations(userId);
            case "marketing_coupons" -> mapper.selectMarketingCoupons(userId);
            case "complaints" -> Map.of("tickets", mapper.selectComplaints(userId), "logs", mapper.selectComplaintLogs(userId));
            case "questions" -> Map.of("questions", mapper.selectQuestions(userId), "answers", mapper.selectAnswers(userId));
            case "dish_reviews" -> mapper.selectDishReviews(userId);
            case "activities" -> Map.of("creatorClaims", mapper.selectCreatorClaims(userId),
                    "seckillClaims", mapper.selectSeckillClaims(userId), "groupbuyMemberships", mapper.selectGroupbuyMemberships(userId),
                    "experimentAssignments", mapper.selectExperimentAssignments(userId));
            case "behavior" -> mapper.selectBehaviorEvents(userId);
            default -> throw new IllegalArgumentException("modules 包含不支持的类型");
        };
    }

    public Map<String, Object> accountRecords(Long userId) {
        // Device tokens, refresh hashes and internal risk rules are deliberately absent from these projections.
        return Map.of("policies", mapper.selectPolicyLogs(userId), "devices", mapper.selectDevices(userId),
                "sessions", mapper.selectSessions(userId), "certifications", mapper.selectCertifications(userId),
                "appeals", mapper.selectAppeals(userId), "riskEvents", mapper.selectRiskEvents(userId));
    }

    public List<Map<String, Object>> reviewInteractions(Long userId) { return mapper.selectReviewInteractions(userId); }
    public List<Map<String, Object>> postInteractions(Long userId) { return mapper.selectPostInteractions(userId); }
    public List<Map<String, Object>> messageReports(Long userId) { return mapper.selectMessageReports(userId); }
    public List<Map<String, Object>> messageBlocks(Long userId) { return mapper.selectMessageBlocks(userId); }
    public Map<String, List<Map<String, Object>>> orderRecords(Long userId) {
        return Map.of("payments", mapper.selectPayments(userId), "refunds", mapper.selectRefunds(userId), "coupons", mapper.selectCoupons(userId));
    }
    public List<Map<String, Object>> reservationLogs(Long userId) { return mapper.selectReservationLogs(userId); }

    /** Must share the task/account lock and transaction; any domain failure rolls back the deletion. */
    @Transactional(propagation = Propagation.MANDATORY)
    public void deleteAccountData(Long userId) {
        mapper.anonymizeInvoiceTitles(userId);
        mapper.anonymizeInvoices(userId);
        // Child queries run before the parent's owner is removed. Role checks distinguish same-number merchant/admin IDs.
        mapper.anonymizeTicketMessages(userId);
        mapper.anonymizeTickets(userId);
        mapper.anonymizeConsultMessages(userId);
        mapper.anonymizeConsultSessions(userId);
        mapper.anonymizeComplaintLogs(userId);
        mapper.anonymizeComplaints(userId);
        mapper.anonymizeWaitlist(userId);
        mapper.deleteTranslations(userId);
        mapper.anonymizeQuestions(userId);
        mapper.anonymizeAnswers(userId);
        mapper.anonymizeDishReviews(userId);
        mapper.deleteBehaviorEvents(userId);
        mapper.deleteExperimentAssignments(userId);
        mapper.deletePendingCreatorClaims(userId);
        mapper.anonymizeCreatorClaims(userId);
        mapper.anonymizeRiskEvents(userId);

        List<Long> fingerprints = mapper.lockAffectedFingerprints(userId);
        mapper.deleteFingerprintUsers(userId);
        for (Long id : fingerprints) {
            mapper.refreshFingerprint(id, userId);
            mapper.deleteUnsharedFingerprint(id);
        }
        List<Long> events = mapper.lockAffectedSeckillEvents(userId);
        mapper.deleteSeckillClaims(userId);
        for (Long id : events) mapper.refreshSeckillSold(id);
        List<Long> teams = mapper.lockAffectedGroupbuyTeams(userId);
        mapper.deleteGroupbuyMembers(userId);
        for (Long id : teams) mapper.refreshGroupbuyTeam(id, userId);
        List<Long> reviews = mapper.lockAffectedReviews(userId);
        mapper.deleteReviewLikes(userId);
        mapper.deleteHelpfulVotes(userId);
        for (Long id : reviews) mapper.refreshReviewCounts(id);
        List<Long> posts = mapper.lockAffectedPosts(userId);
        mapper.deletePostLikes(userId);
        for (Long id : posts) mapper.refreshPostLikes(id);
        mapper.deleteFavorites(userId);
        mapper.anonymizeReviewCommentReports(userId);
        mapper.anonymizePostCommentReports(userId);
        mapper.anonymizeMessageReportTargets(userId);

        List<Long> slots = mapper.lockReservationSlots(userId);
        mapper.anonymizeReservationLogs(userId);
        mapper.anonymizeReservations(userId);
        for (Long id : slots) mapper.refreshReservationCapacity(id);
        List<Long> products = mapper.lockPendingPointsProducts(userId);
        for (Long id : products) mapper.restorePendingPointsStock(id, userId);
        mapper.cancelPendingPointsExchanges(userId);
        mapper.minimizePointsExchanges(userId);
        // Preserve monetary identities as links to the scrubbed account for refunds, settlement and issued entitlements.
        mapper.minimizeMarketingCoupons(userId);
        mapper.minimizePayments(userId);
        mapper.minimizeRefunds(userId);
        mapper.stopCouponReminders(userId);
        mapper.minimizePolicyLogs(userId);
        mapper.deleteCertifications(userId);
        mapper.minimizeAppeals(userId);
        mapper.minimizeAutomodHits(userId);
        mapper.minimizeAdClicks(userId);
        mapper.minimizeAuditLogs(userId);
        mapper.deleteSessionCredentials(userId);
        mapper.clearDeviceIdentifiers(userId);
        mapper.minimizeDeleteTasks(userId);
        mapper.revokeExportTasks(userId);
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void unlinkConversations(Long userId) {
        mapper.anonymizeConversations(userId);
    }
}
