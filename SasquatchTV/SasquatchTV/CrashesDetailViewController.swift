import UIKit

class CrashesDetailViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    var crash: MSCrash!

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = crash.title
        descriptionLabel.text = crash.desc
    }

    @IBAction func doCrash() {
        crash.crash()
    }
    
}
