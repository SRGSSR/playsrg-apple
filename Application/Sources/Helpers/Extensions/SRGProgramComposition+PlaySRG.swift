//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SRGDataProviderModel

extension SRGProgramComposition {
    /**
     *  Return the program at the specified date, if any.
     */
    @objc func play_program(at date: Date) -> SRGProgram? {
        programs?.first(where: { $0.play_containsDate(date) })
    }

    /**
     *  Returns only programs matching in a given date range. The range can be open or possibly half-open. If media URNs
     *  are provided, only matching programs will be returned.
     */
    @objc func play_programs(from fromDate: Date?, to toDate: Date?, withMediaURNs mediaURNs: [String]?) -> [SRGProgram] {
        programs?.filter { program in
            if let fromDate, program.startDate < fromDate {
                return false
            }

            if let toDate, toDate < program.startDate {
                return false
            }

            if let mediaURNs {
                guard let mediaUrn = program.mediaURN else { return false }
                return mediaURNs.contains(mediaUrn)
            }

            return true
        } ?? []
    }
}
