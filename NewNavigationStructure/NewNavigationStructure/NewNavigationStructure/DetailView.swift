import SwiftUI

struct DetailView<R: Router>: View where R.Path: Hashable {
    let id: String
    let router: R

    var body: some View {
        VStack {
            Text("Detail for ID: \(id)")
            if let editable = router as? any EditableDetailRouter {
                Button("Edit") { editable.pushEdit(id) }
            }
            Button("Back") { router.pop() }
        }
    }
}
