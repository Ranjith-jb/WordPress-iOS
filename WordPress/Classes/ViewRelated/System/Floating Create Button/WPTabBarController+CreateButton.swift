import Gridicons

extension FloatingActionButton {
    class func makeCreateButton() -> FloatingActionButton {
        let button = FloatingActionButton(image: Gridicon.iconOfType(.create))
        button.accessibilityLabel = NSLocalizedString("Create", comment: "Accessibility label for create floating action button")
        button.accessibilityIdentifier = "floatingCreateButton"
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
}

extension WPTabBarController {

    private enum Constants {
        static let padding: CGFloat = -16
        static let heightWidth: CGFloat = 56
    }

    @objc private func showCreateSheet() {
        showPostTab()
    }

    @objc func addCreateButton() -> FloatingActionButton? {
        guard let trailingAnchor = blogListSplitViewController.viewControllers.first?.view.trailingAnchor else {
            return nil
        }
        let button = addFloatingButton(trailingAnchor: trailingAnchor, bottomAnchor: tabBar.topAnchor)
        button.addTarget(self, action: #selector(showCreateSheet), for: .touchUpInside)

        return button
    }

    /// Sets up the HideShowCoordinator object
    /// - Parameter view: The view to hide & show
    @objc func setupHideShowCoordinator(view: UIView) -> HideShowCoordinator {
        let coordinator = HideShowCoordinator()

        let showForNavigation: (UIViewController) -> Bool = { viewController in
            let classes = [BlogDetailsViewController.self, PostListViewController.self, PageListViewController.self]
            let vcType = type(of: viewController)
            return classes.contains { classType in
                return vcType == classType
            }
        }

        coordinator.observe(blogListNavigationController, showFor: showForNavigation, view: view)

        let showForTab: (UIViewController) -> Bool = { [weak self] viewController in
            return viewController == self?.blogListSplitViewController
        }

        coordinator.observe(self, showFor: showForTab, view: view)

        return coordinator
    }

    /// Adds a "Floating Action Button" to the UIViewController's `view`
    /// - Parameters:
    ///   - trailingAnchor: The trailing anchor to anchor the button to, separated by `Constants.padding`
    ///   - bottomAnchor: The bottom anchor to anchor the button to, separated by `Constants.padding`
    private func addFloatingButton(trailingAnchor: NSLayoutXAxisAnchor, bottomAnchor: NSLayoutYAxisAnchor) -> FloatingActionButton {
        let button = FloatingActionButton.makeCreateButton()

        view.addSubview(button)

        let trailingConstraint = button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: Constants.padding)
        button.trailingConstraint = trailingConstraint

        NSLayoutConstraint.activate([
            trailingConstraint,
            button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: Constants.padding),
            button.heightAnchor.constraint(equalToConstant: Constants.heightWidth),
            button.widthAnchor.constraint(equalToConstant: Constants.heightWidth)
        ])

        return button
    }
}
