import UIKit
import AVKit

class BackgroundModeView: UIView {
    private let dimmedCover: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var playerLooper: AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?
    private var queuePlayer: AVQueuePlayer?

    init(frame: CGRect, videoURL: URL) {
        super.init(frame: frame)
        setupVideoView(with: videoURL)
        setupDimmedCover()
        observeAppLifecycle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupVideoView(with videoURL: URL) {
        let playerItem = AVPlayerItem(url: videoURL)
        let player = AVQueuePlayer(playerItem: playerItem)
        player.volume = 0.1
        self.queuePlayer = player
        self.playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        layer.insertSublayer(playerLayer, at: 0)
        self.playerLayer = playerLayer

        player.play()
    }

    private func setupDimmedCover() {
        addSubview(dimmedCover)
        NSLayoutConstraint.activate([
            dimmedCover.topAnchor.constraint(equalTo: topAnchor),
            dimmedCover.bottomAnchor.constraint(equalTo: bottomAnchor),
            dimmedCover.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimmedCover.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }

    // MARK: - App Lifecycle Handling

    private func observeAppLifecycle() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc private func handleDidEnterBackground() {
        print("🌙 App moved to background — pausing video")
        queuePlayer?.pause()
    }

    @objc private func handleWillEnterForeground() {
        print("☀️ App moved to foreground — resuming video")
        queuePlayer?.play()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
