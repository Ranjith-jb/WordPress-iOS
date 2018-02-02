import UIKit

class SiteCreationCreateSiteViewController: NUXViewController {

    // MARK: - Properties

    @IBOutlet weak var layingFoundationLabel: UILabel!
    @IBOutlet weak var retrievingInformationLabel: UILabel!
    @IBOutlet weak var configureContentLabel: UILabel!
    @IBOutlet weak var configureStyleLabel: UILabel!
    @IBOutlet weak var preparingFrontendLabel: UILabel!

    private var newSite: Blog?
    private var errorMessage: String?
    private var lastStatus: SiteCreationStatus?
    private var returnToViewController: UIViewController?

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        setLabelText()
        createSite()
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? SiteCreationEpilogueViewController {
            vc.siteToShow = newSite
        }

        if let vc = segue.destination as? NoResultsViewController {
            let title = NSLocalizedString("Something went wrong...", comment: "Primary message on site creation error page.")
            let buttonTitle = NSLocalizedString("Try again", comment: "Button text on site creation error page.")
            let imageName = "site-creation-error"

            vc.delegate = self
            vc.configure(title: title, buttonTitle: buttonTitle, subTitle: errorMessage, image: imageName)
            vc.hideBackButton()
            vc.addWordPressLogoToNavController()
        }
    }

}

// MARK: - View Configuration Extension

private extension SiteCreationCreateSiteViewController {

    func configureView() {
        WPStyleGuide.configureColors(for: view, andTableView: nil)
        addWordPressLogoToNavController()
        // Remove help button.
        navigationItem.rightBarButtonItems = nil
        // Remove Back button. There's no going back now!
        navigationItem.hidesBackButton = true
    }

    func setLabelText() {
        layingFoundationLabel.text = NSLocalizedString("Laying site foundation...", comment: "Text shown during the site creation process when it is on the first step.")
        retrievingInformationLabel.text = NSLocalizedString("Retrieving site information...", comment: "Text shown during the site creation process when it is on the second step.")
        configureContentLabel.text = NSLocalizedString("Configure site content...", comment: "Text shown during the site creation process when it is on the third step.")
        configureStyleLabel.text = NSLocalizedString("Configure site style...", comment: "Text shown during the site creation process when it is on the fourth step.")
        preparingFrontendLabel.text = NSLocalizedString("Preparing frontend...", comment: "Text shown during the site creation process when it is on the fifth step.")
    }

}

// MARK: - Site Creation Extension

private extension SiteCreationCreateSiteViewController {

    func createSite() {

        // Make sure we have all required info before proceeding.
        if let validationError = SiteCreationFields.validateFields() {
            setErrorMessage(for: validationError)
            DDLogError("Error while creating site: \(String(describing: errorMessage))")
            self.performSegue(withIdentifier: .showSiteCreationError, sender: self)
            return
        }

        // Blocks for Create Site process

        let statusBlock = { (status: SiteCreationStatus) in
            self.lastStatus = status
            self.showStepLabelForStatus(status)
        }

        let successBlock = { (blog: Blog) in

            // Touch site so the app recognizes it as the last used.
            // Primarily so the 'write first post' action from the epilogue
            // defaults to the new site.
            if let siteUrl = blog.url {
                RecentSitesService().touch(site: siteUrl)
            }

            self.newSite = blog
            self.performSegue(withIdentifier: .showSiteCreationEpilogue, sender: self)
        }

        let failureBlock = { (error: Error?) in
            self.setErrorMessageForLastStatus()
            self.performSegue(withIdentifier: .showSiteCreationError, sender: self)
        }

        // Start the site creation process
        let siteCreationFields = SiteCreationFields.sharedInstance
        let service = SiteCreationService(managedObjectContext: ContextManager.sharedInstance().mainContext)
        service.createSite(siteURL: siteCreationFields.domain,
                           siteTitle: siteCreationFields.title,
                           siteTagline: siteCreationFields.tagline,
                           siteTheme: siteCreationFields.theme,
                           status: statusBlock,
                           success: successBlock,
                           failure: failureBlock)
    }

    func showStepLabelForStatus(_ status: SiteCreationStatus) {

        let labelToUpdate: UILabel = {
            switch status {
            case .validating:
                return layingFoundationLabel
            case .gettingDefaultAccount, .creatingSite:
                return retrievingInformationLabel
            case .settingTagline:
                return configureContentLabel
            case .settingTheme:
                return configureStyleLabel
            case .syncing:
                return preparingFrontendLabel
            }
        }()

        labelToUpdate.font = WPStyleGuide.fontForTextStyle(.headline)
        labelToUpdate.textColor = WPStyleGuide.darkGrey()
    }

}

// MARK: - Error Handling Extension

private extension SiteCreationCreateSiteViewController {

    // Possible views to direct the 'Try again' button to when validation errors occur.
    enum DestinationViews {
        case themeSelection
        case details
        case domainSuggestion
    }

    /// Determines the error message displayed to the user depending on
    /// the validation error that occurred.
    ///
    /// - Parameter validationError: validation error type returned by SiteCreationFields.validation
    ///
    func setErrorMessage(for validationError: SiteCreationFieldsError) {
        switch validationError {
        case .missingTitle:
            setReturnViewController(for: .details)
            errorMessage = NSLocalizedString("The Site Title is missing.", comment: "Error shown during site creation process when the site title is missing.")
        case .missingDomain:
            setReturnViewController(for: .domainSuggestion)
            errorMessage = NSLocalizedString("The Site Domain is missing.", comment: "Error shown during site creation process when the site domain is missing.")
        case .domainContainsWordPressDotCom:
            setReturnViewController(for: .domainSuggestion)
            errorMessage = NSLocalizedString("The Site Domain contains wordpress.com.", comment: "Error shown during site creation process when the site domain contains wordpress.com.")
        case .missingTheme:
            setReturnViewController(for: .themeSelection)
            errorMessage = NSLocalizedString("The Site Theme is missing.", comment: "Error shown during site creation process when the site theme is missing.")
        }
    }

    /// Determines the error message displayed to the user depending on the last status
    /// reached in the site creation process, i.e the step it failed on.
    ///
    func setErrorMessageForLastStatus() {
        guard let lastStatus = lastStatus else {
            return
        }

        errorMessage = {
            switch lastStatus {
            case .validating:
                return NSLocalizedString("The Site Domain is invalid.", comment: "Error shown during site creation process when the site domain validation fails.")
            case .gettingDefaultAccount:
                return NSLocalizedString("We were unable to get your account information.", comment: "Error shown during site creation process when the account cannot be obtained.")
            case .creatingSite:
                return NSLocalizedString("We were unable to create the site.", comment: "Error shown during site creation process when the site creation fails.")
            case .settingTagline:
                return NSLocalizedString("We were unable to set the Site Tagline.", comment: "Error shown during site creation process when setting the site tagline fails.")
            case .settingTheme:
                return NSLocalizedString("We were unable to set the Site Theme.", comment: "Error shown during site creation process when setting the site theme fails.")
            case .syncing:
                return NSLocalizedString("We were unable to sync your account information.", comment: "Error shown during site creation process when syncing the account fails.")
            }
        }()
    }

    /// Finds the destination view controller in the navigation controller view stack.
    ///
    /// - Parameter destination: The view to return to.
    ///
    func setReturnViewController(for destination: DestinationViews) {

        guard let navController = navigationController else {
            return
        }

        let viewControllers = navController.viewControllers

        returnToViewController = {
            switch destination {
            case .themeSelection:
                return viewControllers.first(where: {
                    $0.isKind(of: SiteCreationThemeSelectionViewController.self)
                })
            case .details:
                return viewControllers.first(where: {
                    $0.isKind(of: SiteCreationSiteDetailsViewController.self)
                })
            case .domainSuggestion:
                return viewControllers.first(where: {
                    $0.isKind(of: SiteCreationDomainsViewController.self)
                })
            }
        }()
    }
}

// MARK: - NoResultsViewControllerDelegate

extension SiteCreationCreateSiteViewController: NoResultsViewControllerDelegate {

    func actionButtonPressed() {
        if let returnToViewController = returnToViewController {
            navigationController?.popToViewController(returnToViewController, animated: true)
        }
    }

}
