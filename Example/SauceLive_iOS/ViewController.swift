import UIKit
import SauceLive_iOS

class ViewController: UIViewController, UITextFieldDelegate {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let urlTextField = UITextField()
    private var checkBoxes = [UIButton]()
    private let openWebViewButton = UIButton()
    private let openPIPViewButton = UIButton()
    private var selectedMessageHandlers = [MessageHandlerName]()
    
    // Segmented Control 추가
    private let environmentSegmentedControl = UISegmentedControl(items: ["Dev", "Stage", "Prod"])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        setupUI()
        setupCheckBoxes()
        setupGestureToHideKeyboard()
    }
    
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // URL Text Field 설정
        contentView.addSubview(urlTextField)
        urlTextField.borderStyle = .roundedRect
        urlTextField.placeholder = "Enter your broadcastId here"
        urlTextField.delegate = self
        urlTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            urlTextField.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 20),
            urlTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            urlTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        // Segmented Control 설정
        contentView.addSubview(environmentSegmentedControl)
        environmentSegmentedControl.selectedSegmentIndex = 0
        environmentSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            environmentSegmentedControl.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 20),
            environmentSegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            environmentSegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
        
        // Open WebView Button 설정
        contentView.addSubview(openWebViewButton)
        openWebViewButton.setTitle("Open Web View", for: .normal)
        openWebViewButton.backgroundColor = .systemBlue
        openWebViewButton.addTarget(self, action: #selector(openWebViewController), for: .touchUpInside)
        openWebViewButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            openWebViewButton.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            openWebViewButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            openWebViewButton.heightAnchor.constraint(equalToConstant: 50),
            openWebViewButton.widthAnchor.constraint(equalToConstant: 200)
        ])
        
        // Open PIP View Button 설정
        contentView.addSubview(openPIPViewButton)
        openPIPViewButton.setTitle("Open PIP View", for: .normal)
        openPIPViewButton.backgroundColor = .systemGreen
        openPIPViewButton.addTarget(self, action: #selector(openPIPViewController), for: .touchUpInside)
        openPIPViewButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            openPIPViewButton.topAnchor.constraint(equalTo: openWebViewButton.bottomAnchor, constant: 20),
            openPIPViewButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            openPIPViewButton.heightAnchor.constraint(equalToConstant: 50),
            openPIPViewButton.widthAnchor.constraint(equalToConstant: 200),
        ])
    }
    
    private func setupCheckBoxes() {
        let messageHandlerNames: [MessageHandlerName] = [.enter, .exit, .onLogin, .onProduct, .onBanner, .onShare, .onPictureInPicture, .onReward, .onReloading]
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: environmentSegmentedControl.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: openWebViewButton.topAnchor, constant: -20)
        ])
        
        messageHandlerNames.enumerated().forEach { (index, name) in
            let button = UIButton(type: .system)
            button.setTitle(name.rawValue, for: .normal)
            button.tag = index
            button.setTitleColor(.black, for: .normal)
            button.addTarget(self, action: #selector(toggleCheckBox(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
            checkBoxes.append(button)
        }
    }
    
    private var handlerStates: [MessageHandlerName: Bool] = [
        .enter: false,
        .exit: false,
        .onLogin: false,
        .onProduct: false,
        .onBanner: false,
        .onShare: false,
        .onPictureInPicture: false,
        .onReloading: false,
        .onReward: false
    ]
    
    @objc private func toggleCheckBox(_ sender: UIButton) {
        guard let title = sender.title(for: .normal),
              let selectedName = MessageHandlerName(rawValue: title) else { return }

        let isEnabled = handlerStates[selectedName] ?? false
        handlerStates[selectedName] = !isEnabled

        sender.layer.borderWidth = !isEnabled ? 2 : 0
        sender.layer.borderColor = !isEnabled ? UIColor.systemBlue.cgColor : nil
        sender.setTitleColor(!isEnabled ? .systemBlue : .black, for: .normal)
    }
    
    @objc private func openWebViewController() {
        guard let urlString = urlTextField.text, urlString.count != 0 else {
            return
        }
        
        let selectedEnvironment = environmentSegmentedControl.titleForSegment(at: environmentSegmentedControl.selectedSegmentIndex)
        
        let sauceViewController = SauceViewController()
        sauceViewController.urlString = urlString
        sauceViewController.handlerStates = handlerStates
        //sauceViewController.environment = selectedEnvironment
        PIPKit.show(with: sauceViewController)
    }
    
    @objc private func openPIPViewController() {
        guard let urlString = urlTextField.text, urlString.count != 0 else {
            return
        }
        
        let selectedEnvironment = environmentSegmentedControl.titleForSegment(at: environmentSegmentedControl.selectedSegmentIndex)
        
        let sauceViewController = SauceViewController()
        sauceViewController.urlString = urlString
        sauceViewController.handlerStates = handlerStates
        //sauceViewController.environment = selectedEnvironment
        PIPKit.show(with: sauceViewController)
    }
    
    private func setupGestureToHideKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
