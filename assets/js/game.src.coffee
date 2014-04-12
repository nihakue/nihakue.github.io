
class Mob extends Phaser.Sprite
# Static Functions
  @preload: (game, name) ->
    game.load.atlasJSONHash(
      name
      "assets/atlas/#{name}.png"
      "assets/atlas/#{name}.json"
      )

# Instance Functions
  constructor: ->
    super
    @anchor =
        x: 0.5
        y: 0.5
    @initPhysics()

  initPhysics: =>
    @game.physics.arcade.enable(@)
    @body.bounce.y = 0.2
    @body.gravity.y = 1500
    @body.collideWorldBounds = true

  goLeft: ->
    @body.velocity.x = -@speed
    @scale.setTo(-1, 1)
    @animations.play('walk') if @body.touching.down

  goRight: ->
    @body.velocity.x = @speed
    @scale.setTo(1, 1)
    @animations.play('walk') if @body.touching.down

  idle: ->
    if @body.touching.down
      @animations.play('idle')

  jump: ->
    @body.velocity.y = -@jumpStrength
    @animations.play('jump')
class Player extends Mob
  constructor: ->
    super
    @cursors = null
    @speed = 300
    @jumpStrength = 700
    @health = 10

  create: ->
    @initAnimations()

    @cursors = @game.input.keyboard.createCursorKeys()
    @hurtKey = @game.input.keyboard.addKey(Phaser.Keyboard.SPACEBAR)
    @hurtKey.onDown.add(@hurt, this)
    @game.input.keyboard.addKeyCapture(Phaser.Keyboard.SPACEBAR)

  initAnimations: ->
    # Load all animations
    @animations.add('jump',
      Phaser.Animation.generateFrameNames('jump', 0, 7, '', 2)
      5, false)

    @animations.add('idle',
      Phaser.Animation.generateFrameNames('idle', 0, 8, '', 2),
      5, true)

    @animations.add('walk',
      Phaser.Animation.generateFrameNames('walk', 0, 12, '', 2),
      15, true)

    @animations.add('into_exhausted',
      Phaser.Animation.generateFrameNames('into_exhausted', 0, 3, '', 2),
      5, false)

    @animations.add('exhausted',
    Phaser.Animation.generateFrameNames('exhausted', 0, 7, '', 2),
    5, true)

  update: ->
    @handleControl()

  handleControl: ->
    @body.velocity.x = 0

    if @cursors.left.isDown
      @goLeft()
    else if @cursors.right.isDown
      @goRight()
    else
      @idle()

    @jump() if @cursors.up.isDown and @body.touching.down

  idle: ->
    if @body.touching.down
      if @health > 5
          @animations.play('idle')
        else 
          @animations.play('exhausted')

  hurt: ->
    @health -= 1
class Snell
# Static functions
  @preload: (game) ->
    game.load.image('sky', 'assets/images/sky.png')
    game.load.image('ground', 'assets/images/platform.png')
    game.load.image('star', 'assets/images/star.png')

    Mob.preload(game, 'sqot')

# Instance functions
  constructor: (@game, @player) ->
    @platforms = null
    @stars = null
    @sqot = null

  create: ->
    @game.add.sprite(0, 0, 'sky')
    
    @sqots = @game.add.group()

    @platforms = @game.add.group()
    @platforms.enableBody = true

    ground = @platforms.create(0, @game.world.height - 64, 'ground')
    ground.scale.setTo(2, 2)
    ground.body.immovable = true

    ledge = @platforms.create(400, 400, 'ground')
    ledge.body.immovable = true

    ledge = @platforms.create(-150, 250, 'ground')
    ledge.body.immovable = true

    @stars = @game.add.group()
    @stars.enableBody = true
    # Create some sqots
    for i in [0..100]
      @sqots.add(new Sqot(@player, @game, @game.world.randomX, @game.world.randomY, 'sqot', 'walk00'))


    # Create some stars
    for i in [0..12]
      star = @stars.create(i * 70, 0, 'star')
      star.body.gravity.y = 6
      star.body.bounce.y = 0.7 + Math.random() * 0.2

  update: ->
    @game.physics.arcade.collide(@stars, @platforms);
    @game.physics.arcade.collide(@sqots, @platforms);
    @game.physics.arcade.overlap(
      @player,
      @sqots,
      @player.hurt,
      null, @player)
    @sqots.callAll('update')
class Sqot extends Mob
  constructor: (@player, args...) ->
    super(args...)
    @speed = Math.random() * 200
    @jumpStrength = 500
    @initAnimations()

  initAnimations: ->
    @animations.add('walk',
    Phaser.Animation.generateFrameNames('walk', 0, 3, '', 2),
    5, true)

  update: ->
    @body.velocity.x = 0

    if @player.x > @x
      @goRight()
    else
      @goLeft()

    if .99 < Math.random()
      @jump()
window.onload = ->
  @game = new Phaser.Game(800, 600, Phaser.AUTO)
  @game.state.add 'main', new MainState, true

class LogoSprite extends Phaser.Sprite
  constructor: ->
    super
    @anchor =
      x: 0.5
      y: 0.5

class MainState extends Phaser.State
  constructor: -> super

  preload: ->
    Mob.preload(@game, 'serge')
    Snell.preload(@game)

  create: ->
    @game.physics.startSystem(Phaser.Physics.ARCADE)
    @game.time.advancedTiming = true

    
    @player = new Player(@game, 32, @game.world.height - 150, 'serge', 'idle00')
    @snell = new Snell(@game, @player)

    @hud = new Hud(@game, @player)

    @snell.create()
    @player.create()
    @hud.create()

    @game.world.add(@player)

    if @game.scaleToFit
      @game.stage.scaleMode = Phaser.StageScaleMode.SHOW_ALL
      @game.stage.scale.setShowAll()
      @game.stage.scale.refresh()

  update: ->
    @game.physics.arcade.collide(@player, @snell.platforms);
    @game.physics.arcade.overlap(
      @player,
      @snell.stars,
      @collectStar,
      null, this);

    @snell.update()
    @player.update()
    @hud.update()
    # @debugText.text = @player.body.deltaY()

  # render: ->
  #   @game.debug.body(@player)

  collectStar: (player, star) ->
    star.kill()
    @hud.score += 10;
    @hud.scoreText.text = 'Score: ' + @hud.score;

class Hud
  constructor: (@game, @player) ->
    @score = 0
    @scoreText = null

  create: ->
    scoreStyle =
      font: "12px Arial"
      fill: "#000"

    @scoreText = @game.add.text(
      16, 16, 'Score: 0'
      scoreStyle)

  update: ->
    @scoreText.text = "fps: #{@game.time.fps} HP: #{@player.health}\nScore:  #{@score}";