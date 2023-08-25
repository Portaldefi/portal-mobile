//
//  FiatCurrency.swift
//  Portal
//
//  Created by farid on 23/8/22.
//

import Foundation

struct FiatCurrency: Codable {
    let code: String
    let rate: Decimal
    
    var name: String {
        Self.names[code] ?? "Unknown"
    }
    
    var symbol: String {
        getSymbolForCurrencyCode(code: code) ?? "-"
    }
    
    init(code: String, rate: Decimal = 1) {
        self.code = code
        self.rate = rate
    }
    
    private func getSymbolForCurrencyCode(code: String) -> String? {
        var candidates: [String] = []
        let locales: [String] = NSLocale.availableLocaleIdentifiers
        for localeID in locales {
            guard let symbol = findMatchingSymbol(localeID: localeID, currencyCode: code) else {
                continue
            }
            if symbol.count == 1 {
                return symbol
            }
            candidates.append(symbol)
        }
        let sorted = sortAscByLength(list: candidates)
        if sorted.count < 1 {
            return nil
        }
        return sorted[0]
    }
    
    private func findMatchingSymbol(localeID: String, currencyCode: String) -> String? {
        let locale = Locale(identifier: localeID as String)
        guard let code = locale.currencyCode else {
            return nil
        }
        if code != currencyCode {
            return nil
        }
        guard let symbol = locale.currencySymbol else {
            return nil
        }
        return symbol
    }
    
    private func sortAscByLength(list: [String]) -> [String] {
        return list.sorted(by: { $0.count < $1.count })
    }
}

extension FiatCurrency: Hashable, Equatable {
    public static func ==(lhs: FiatCurrency, rhs: FiatCurrency) -> Bool {
        lhs.code == rhs.code
    }
}

extension FiatCurrency {
    static var names: [String : String] {
        [
            "AED": "United Arab Emirates Dirham",
            "AFN": "Afghan Afghani",
            "ALL": "Albanian Lek",
            "AMD": "Armenian Dram",
            "ANG": "Netherlands Antillean Guilder",
            "AOA": "Angolan Kwanza",
            "ARS": "Argentine Peso",
            "AUD": "Australian Dollar",
            "AWG": "Aruban Florin",
            "AZN": "Azerbaijani Manat",
            "BAM": "Bosnia-Herzegovina Convertible Mark",
            "BBD": "Barbadian Dollar",
            "BDT": "Bangladeshi Taka",
            "BGN": "Bulgarian Lev",
            "BHD": "Bahraini Dinar",
            "BIF": "Burundian Franc",
            "BMD": "Bermudan Dollar",
            "BND": "Brunei Dollar",
            "BOB": "Bolivian Boliviano",
            "BRL": "Brazilian Real",
            "BSD": "Bahamian Dollar",
            "BTN": "Bhutanese Ngultrum",
            "BWP": "Botswanan Pula",
            "BYN": "New Belarusian Ruble",
            "BZD": "Belize Dollar",
            "CAD": "Canadian Dollar",
            "CDF": "Congolese Franc",
            "CHF": "Swiss Franc",
            "CLP": "Chilean Peso",
            "CNY": "Chinese Yuan",
            "COP": "Colombian Peso",
            "CRC": "Costa Rican Colón",
            "CUP": "Cuban Peso",
            "CVE": "Cape Verdean Escudo",
            "CZK": "Czech Republic Koruna",
            "DJF": "Djiboutian Franc",
            "DKK": "Danish Krone",
            "DOP": "Dominican Peso",
            "DZD": "Algerian Dinar",
            "EGP": "Egyptian Pound",
            "ERN": "Eritrean Nakfa",
            "ETB": "Ethiopian Birr",
            "EUR": "Euro",
            "FJD": "Fijian Dollar",
            "FKP": "Falkland Islands Pound",
            "GBP": "British Pound Sterling",
            "GEL": "Georgian Lari",
            "GHS": "Ghanaian Cedi",
            "GIP": "Gibraltar Pound",
            "GMD": "Gambian Dalasi",
            "GNF": "Guinean Franc",
            "GTQ": "Guatemalan Quetzal",
            "GYD": "Guyanaese Dollar",
            "HKD": "Hong Kong Dollar",
            "HNL": "Honduran Lempira",
            "HTG": "Haitian Gourde",
            "HUF": "Hungarian Forint",
            "IDR": "Indonesian Rupiah",
            "ILS": "Israeli New Sheqel",
            "INR": "Indian Rupee",
            "IQD": "Iraqi Dinar",
            "IRR": "Iranian Rial",
            "ISK": "Icelandic Króna",
            "JMD": "Jamaican Dollar",
            "JOD": "Jordanian Dinar",
            "JPY": "Japanese Yen",
            "KES": "Kenyan Shilling",
            "KGS": "Kyrgystani Som",
            "KHR": "Cambodian Riel",
            "KMF": "Comorian Franc",
            "KPW": "North Korean Won",
            "KRW": "South Korean Won",
            "KWD": "Kuwaiti Dinar",
            "KYD": "Cayman Islands Dollar",
            "KZT": "Kazakhstani Tenge",
            "LAK": "Laotian Kip",
            "LBP": "Lebanese Pound",
            "LKR": "Sri Lankan Rupee",
            "LRD": "Liberian Dollar",
            "LYD": "Libyan Dinar",
            "MAD": "Moroccan Dirham",
            "MDL": "Moldovan Leu",
            "MGA": "Malagasy Ariary",
            "MKD": "Macedonian Denar",
            "MMK": "Myanma Kyat",
            "MNT": "Mongolian Tugrik",
            "MOP": "Macanese Pataca",
            "MUR": "Mauritian Rupee",
            "MVR": "Maldivian Rufiyaa",
            "MWK": "Malawian Kwacha",
            "MXN": "Mexican Peso",
            "MYR": "Malaysian Ringgit",
            "MZN": "Mozambican Metical",
            "NAD": "Namibian Dollar",
            "NGN": "Nigerian Naira",
            "NIO": "Nicaraguan Córdoba",
            "NOK": "Norwegian Krone",
            "NPR": "Nepalese Rupee",
            "NZD": "New Zealand Dollar",
            "OMR": "Omani Rial",
            "PAB": "Panamanian Balboa",
            "PEN": "Peruvian Nuevo Sol",
            "PGK": "Papua New Guinean Kina",
            "PHP": "Philippine Peso",
            "PKR": "Pakistani Rupee",
            "PLN": "Polish Zloty",
            "PYG": "Paraguayan Guarani",
            "QAR": "Qatari Rial",
            "RON": "Romanian Leu",
            "RSD": "Serbian Dinar",
            "RUB": "Russian Ruble",
            "RWF": "Rwandan Franc",
            "SAR": "Saudi Riyal",
            "SBD": "Solomon Islands Dollar",
            "SCR": "Seychellois Rupee",
            "SDG": "Sudanese Pound",
            "SEK": "Swedish Krona",
            "SGD": "Singapore Dollar",
            "SHP": "Saint Helena Pound",
            "SLL": "Sierra Leonean Leone",
            "SOS": "Somali Shilling",
            "SRD": "Surinamese Dollar",
            "SYP": "Syrian Pound",
            "SZL": "Swazi Lilangeni",
            "THB": "Thai Baht",
            "TJS": "Tajikistani Somoni",
            "TMT": "Turkmenistani Manat",
            "TND": "Tunisian Dinar",
            "TOP": "Tongan Paʻanga",
            "TRY": "Turkish Lira",
            "TTD": "Trinidad and Tobago Dollar",
            "TWD": "New Taiwan Dollar",
            "TZS": "Tanzanian Shilling",
            "UAH": "Ukrainian Hryvnia",
            "UGX": "Ugandan Shilling",
            "USD": "United States Dollar",
            "UYU": "Uruguayan Peso",
            "UZS": "Uzbekistan Som",
            "VES": "Sovereign Bolivar",
            "VND": "Vietnamese Dong",
            "VUV": "Vanuatu Vatu",
            "WST": "Samoan Tala",
            "XAF": "CFA Franc BEAC",
            "XCD": "East Caribbean Dollar",
            "XOF": "CFA Franc BCEAO",
            "XPF": "CFP Franc",
            "YER": "Yemeni Rial",
            "ZAR": "South African Rand",
            "ZMW": "Zambian Kwacha",
        ]
    }
}
