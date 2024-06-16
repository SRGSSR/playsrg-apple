//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

import SwiftUI

// MARK: View

struct SearchBarView: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let autocapitalizationType: UITextAutocapitalizationType

    init(text: Binding<String>, placeholder: String = "", autocapitalizationType: UITextAutocapitalizationType = .sentences) {
        _text = text
        self.placeholder = placeholder
        self.autocapitalizationType = autocapitalizationType
    }

    final class Cordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func searchBar(_: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
    }

    func makeCoordinator() -> Cordinator {
        return Cordinator(text: $text)
    }

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.backgroundImage = UIImage()
        searchBar.placeholder = placeholder
        searchBar.autocapitalizationType = .none
        searchBar.delegate = context.coordinator
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context _: Context) {
        uiView.text = text
    }
}

// MARK: Preview

struct SearchBarView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SearchBarView(text: .constant(""), placeholder: "Enter something here...")
            SearchBarView(text: .constant("Roger"), placeholder: "Enter something here...")
        }
        .previewLayout(.sizeThatFits)
    }
}
