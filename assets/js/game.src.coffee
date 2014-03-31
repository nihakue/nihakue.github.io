window.onload = ->
  @game = new Phaser.Game(800, 600, Phaser.AUTO)
  @game.state.add 'main', new MainState, true

class LogoSprite extends Phaser.Sprite
  constructor: ->
    super
    @anchor =
      x: 0.5
      y: 0.5

class PlayerSprite extends Phaser.Sprite
  constructor: ->
    super

    @anchor =
      x: 0.5
      y: 0.5

    @speed = 300
    @jumpStrength = 800

    @animations.add('jump',
      Phaser.Animation.generateFrameNames('jump', 0, 7, '', 2)
      5, false)

    @animations.add('idle',
      Phaser.Animation.generateFrameNames('puffed', 0, 8, '', 2),
      5, true)

    @animations.add('walk',
      Phaser.Animation.generateFrameNames('run', 0, 5, '', 2),
      12, true)

  initPhysics: ->
    @body.bounce.y = 0.2
    @body.gravity.y = 1500
    @body.collideWorldBounds = true

  handleControl: (cursors) ->
    @body.velocity.x = 0

    if cursors.left.isDown
      @goLeft()
    else if cursors.right.isDown
      @goRight()
    else
      @idle()

    @jump() if cursors.up.isDown and @body.touching.down

  goLeft: ->
    @body.velocity.x = -@speed
    @scale.setTo(-1, 1)
    @animations.play('walk') if @body.touching.down

  goRight: ->
    @body.velocity.x = @speed
    @scale.setTo(1, 1)
    @animations.play('walk') if @body.touching.down

  idle: ->
    @animations.play('idle') if @body.touching.down

  jump: ->
    @body.velocity.y = -@jumpStrength
    @animations.play('jump')
class MainState extends Phaser.State
  constructor: -> super

  preload: ->
    @game.load.image('sky', 'assets/images/sky.png')
    @game.load.image('ground', 'assets/images/platform.png')
    @game.load.image('star', 'assets/images/star.png')
    # @game.load.spritesheet('guy', 'assets/images/guy.png', 50, 60)

    @game.load.atlasJSONHash(
      'guy'
      'assets/atlas/guy.png'
      'assets/atlas/guy.json'
      )

  create: ->
    @game.physics.startSystem(Phaser.Physics.ARCADE)
    @game.add.sprite(0, 0, 'sky')

    @platforms = @game.add.group()
    @platforms.enableBody = true

    ground = @platforms.create(0, @game.world.height - 64, 'ground')
    ground.scale.setTo(2, 2)
    ground.body.immovable = true

    ledge = @platforms.create(400, 400, 'ground')
    ledge.body.immovable = true

    ledge = @platforms.create(-150, 250, 'ground')
    ledge.body.immovable = true

    @player = new PlayerSprite(@game, 32, (@game.world.height - 150), 'guy')
    @game.world.add(@player)
    @game.physics.arcade.enable(@player)
    @player.initPhysics()

    @stars = game.add.group()
    @stars.enableBody = true

    for i in [0..12]
      star = @stars.create(i * 70, 0, 'star')
      star.body.gravity.y = 6
      star.body.bounce.y = 0.7 + Math.random() * 0.2

    #Score
    @score = 0
    @scoreText = @game.add.text(
      16
      16
      'Score: 0'
      fontSize:
        '32px'
      fill:
        '#000'
    )

    #Controls
    @cursors = @game.input.keyboard.createCursorKeys();

    #Debug Info
    @debugText = @game.add.text(
      50
      50
      ''
      fontSize:
        '18px'
      fill:
        '#000'
      )


    if @game.scaleToFit
      @game.stage.scaleMode = Phaser.StageScaleMode.SHOW_ALL
      @game.stage.scale.setShowAll()
      @game.stage.scale.refresh()

  update: ->
    @game.physics.arcade.collide(@player, @platforms);
    @game.physics.arcade.collide(@stars, @platforms);
    @game.physics.arcade.overlap(@player, @stars, @collectStar, null, this);

    @player.handleControl(@cursors)

    # @debugText.text = @player.body.deltaY()


  collectStar: (player, star) ->
    star.kill()
    @score += 10;
    @scoreText.text = 'Score: ' + @score;
