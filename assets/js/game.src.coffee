class Player
  constructor: (game) ->
    @game = game
    @sprite = null
    @cursors = null
    @speed = 300
    @jumpStrength = 700

  preload: ->
    @game.load.atlasJSONHash(
      'serge'
      'assets/atlas/guy.png'
      'assets/atlas/guy.json'
      )

  create: ->
    @sprite = @game.add.sprite(32, game.world.height - 150, 'serge')
    @sprite.animations.add('jump',
      Phaser.Animation.generateFrameNames('jump', 0, 7, '', 2)
      5, false)

    @sprite.animations.add('idle',
      Phaser.Animation.generateFrameNames('puffed', 0, 8, '', 2),
      5, true)

    @sprite.animations.add('walk',
      Phaser.Animation.generateFrameNames('run', 0, 12, '', 2),
      15, true)
    @sprite.anchor =
      x: 0.5
      y: 0.5

    @initPhysics()
    @cursors = @game.input.keyboard.createCursorKeys()

  update: ->
    @handleControl()

  initPhysics: ->
    @game.physics.arcade.enable(@sprite)
    @sprite.body.bounce.y = 0.2
    @sprite.body.gravity.y = 1500
    @sprite.body.collideWorldBounds = true

  handleControl: ->
    @sprite.body.velocity.x = 0

    if @cursors.left.isDown
      @goLeft()
    else if @cursors.right.isDown
      @goRight()
    else
      @idle()

    @jump() if @cursors.up.isDown and @sprite.body.touching.down

  goLeft: ->
    @sprite.body.velocity.x = -@speed
    @sprite.scale.setTo(-1, 1)
    @sprite.animations.play('walk') if @sprite.body.touching.down

  goRight: ->
    @sprite.body.velocity.x = @speed
    @sprite.scale.setTo(1, 1)
    @sprite.animations.play('walk') if @sprite.body.touching.down

  idle: ->
    @sprite.animations.play('idle') if @sprite.body.touching.down

  jump: ->
    @sprite.body.velocity.y = -@jumpStrength
    @sprite.animations.play('jump')
class Snell
  constructor: (@game) ->
    @platforms = null
    @stars = null

  preload: ->
    @game.load.image('sky', 'assets/images/sky.png')
    @game.load.image('ground', 'assets/images/platform.png')
    @game.load.image('star', 'assets/images/star.png')

  create: ->
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

    @stars = game.add.group()
    @stars.enableBody = true

    for i in [0..12]
      star = @stars.create(i * 70, 0, 'star')
      star.body.gravity.y = 6
      star.body.bounce.y = 0.7 + Math.random() * 0.2

  update: ->
    @game.physics.arcade.collide(@stars, @platforms);
window.onload = ->
  @game = new Phaser.Game(800, 600, Phaser.AUTO)
  @game.state.add 'main', new MainState, true

class LogoSprite extends Phaser.Sprite
  constructor: ->
    super
    @anchor =
      x: 0.5
      y: 0.5

class Player
  constructor: (@game) ->
    @sprite = null
    @cursors = null
    @speed = 300
    @jumpStrength = 700

  preload: ->
    @game.load.atlasJSONHash(
      'serge'
      'assets/atlas/guy.png'
      'assets/atlas/guy.json'
      )

  create: ->
    @sprite = @game.add.sprite(32, game.world.height - 150, 'serge')
    @sprite.animations.add('jump',
      Phaser.Animation.generateFrameNames('jump', 0, 7, '', 2)
      5, false)

    @sprite.animations.add('idle',
      Phaser.Animation.generateFrameNames('puffed', 0, 8, '', 2),
      5, true)

    @sprite.animations.add('walk',
      Phaser.Animation.generateFrameNames('run', 0, 12, '', 2),
      15, true)
    @sprite.anchor =
      x: 0.5
      y: 0.5

    @initPhysics()
    @cursors = @game.input.keyboard.createCursorKeys()

  update: ->
    @handleControl()

  initPhysics: ->
    @game.physics.arcade.enable(@sprite)
    @sprite.body.bounce.y = 0.2
    @sprite.body.gravity.y = 1500
    @sprite.body.collideWorldBounds = true

  handleControl: ->
    @sprite.body.velocity.x = 0

    if @cursors.left.isDown
      @goLeft()
    else if @cursors.right.isDown
      @goRight()
    else
      @idle()

    @jump() if @cursors.up.isDown and @sprite.body.touching.down

  goLeft: ->
    @sprite.body.velocity.x = -@speed
    @sprite.scale.setTo(-1, 1)
    @sprite.animations.play('walk') if @sprite.body.touching.down

  goRight: ->
    @sprite.body.velocity.x = @speed
    @sprite.scale.setTo(1, 1)
    @sprite.animations.play('walk') if @sprite.body.touching.down

  idle: ->
    @sprite.animations.play('idle') if @sprite.body.touching.down

  jump: ->
    @sprite.body.velocity.y = -@jumpStrength
    @sprite.animations.play('jump')
class MainState extends Phaser.State
  constructor: -> super

  preload: ->
    @snell = new Snell(@game)
    @snell.preload()

    @player = new Player(@game)
    @player.preload()

    @hud = new Hud(@game)

  create: ->
    @game.physics.startSystem(Phaser.Physics.ARCADE)

    @snell.create()
    @player.create()
    @hud.create()

    if @game.scaleToFit
      @game.stage.scaleMode = Phaser.StageScaleMode.SHOW_ALL
      @game.stage.scale.setShowAll()
      @game.stage.scale.refresh()

  update: ->
    @game.physics.arcade.collide(@player.sprite, @snell.platforms);
    @game.physics.arcade.overlap(
      @player.sprite,
      @snell.stars,
      @collectStar,
      null, this);

    @snell.update()
    @player.update()
    # @debugText.text = @player.body.deltaY()

  collectStar: (player, star) ->
    star.kill()
    @hud.score += 10;
    @hud.scoreText.text = 'Score: ' + @hud.score;

class Hud
  constructor: (@game) ->
    @score = 0
    @scoreText = null

  create: ->
    @scoreText = @game.add.text(
      16, 16, 'Score: 0'
      fontSize:
        '32px'
      fill:
        '#000')