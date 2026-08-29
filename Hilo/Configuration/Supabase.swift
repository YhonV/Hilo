//
//  Supabase.swift
//  Hilo
//
//  Created by Cactu on 15-08-26.
//
import Foundation
import Supabase

let supabase = SupabaseClient(
  supabaseURL: URL(string: "https://smfstophtxtnbavxyljr.supabase.co")!,
  supabaseKey: Bundle.main.object(forInfoDictionaryKey: "supabaseKey") as? String ?? ""
  
)
