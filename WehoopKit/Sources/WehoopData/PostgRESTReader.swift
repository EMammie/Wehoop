import Contracts
import Foundation
import Supabase

/// Reads the public views and tables through PostgREST as the guest session. Rows decode
/// into Contracts types with their own (snake_case) coding keys, not PostgREST's decoder.
public struct PostgRESTReader: Sendable {
    let client: SupabaseClient
    let auth: AuthSession

    /// `v_schedule` rows of one league in `[from, to)`, by scheduled time.
    public func schedule(league: String, from: Date, to: Date) async throws -> [ScheduleRow] {
        try await auth.ensureSignedIn()
        let response = try await client.from("v_schedule").select()
            .eq("league", value: league)
            .gte("scheduled_at", value: ISODate.format(from))
            .lt("scheduled_at", value: ISODate.format(to))
            .order("scheduled_at")
            .order("id")
            .execute()
        return try decode(response.data)
    }

    /// One `v_schedule` row by game id; nil when there is none.
    public func scheduleRow(id: String) async throws -> ScheduleRow? {
        try await auth.ensureSignedIn()
        let response = try await client.from("v_schedule").select().eq("id", value: id).limit(1).execute()
        let rows: [ScheduleRow] = try decode(response.data)
        return rows.first
    }

    /// Every `leagues` row.
    public func leagues() async throws -> [LeagueRow] {
        try await auth.ensureSignedIn()
        return try decode(try await client.from("leagues").select().order("code").execute().data)
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do { return try APIClient.decoder.decode(T.self, from: data) } catch {
            throw APIError.decoding(String(describing: error))
        }
    }
}
