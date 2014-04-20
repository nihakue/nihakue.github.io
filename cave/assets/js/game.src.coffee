
class Mob extends Phaser.Sprite
# Static Functions
  @preload: (game, name) ->
    game.load.atlasJSONHash(
      name
      "assets/atlas/#{name}.png"
      "assets/atlas/#{name}.json"
      )

  @canCollide: (player, enemy) ->
    not (player.invincible or enemy.invincible)

# Instance Functions
  constructor: ->
    super
    @anchor =
        x: 0.5
        y: 0.5
    @initPhysics()
    @invincible = false

  initPhysics: =>
    @game.physics.arcade.enable(@)
    @body.bounce.y = 0.2
    @body.gravity.y = 1500
    @body.collideWorldBounds = true

  goLeft: (velocity=@speed) ->
    @body.velocity.x = -velocity
    @scale.setTo(-1, 1)
    @animations.play('walk') if @body.touching.down

  goRight: (velocity=@speed) ->
    @body.velocity.x = velocity
    @scale.setTo(1, 1)
    @animations.play('walk') if @body.touching.down

  idle: ->
    if @body.touching.down
      @animations.play('idle')

  jump: (strength=@jumpStrength) ->
    @body.velocity.y = -strength
    @animations.play('jump')

  flash: (duration) ->
    @game.time.events.repeat(
      100, duration / 100,
      () ->
        @alpha = if @alpha is 1 then .75 else 1
      @)


class Player extends Mob
  constructor: ->
    super
    @cursors = null
    @speed = 300
    @jumpStrength = 700
    @health = 10
    @invincibleTime = 2000
    @t_for_fspeed = 300 #miliseconds to reach full speed
    @falling = true

  create: ->
    @initAnimations()
    @body.setSize(@body.width / 1.5, @body.height, 5, 0)

    @cursors = @game.input.keyboard.createCursorKeys()
    @hurtKey = @game.input.keyboard.addKey(Phaser.Keyboard.SPACEBAR)
    @hurtKey.onDown.add(@hurt, this)
    @game.input.keyboard.addKeyCapture(Phaser.Keyboard.SPACEBAR)

  initAnimations: ->
    # Load all animations
    @animations.add('jump',
      Phaser.Animation.generateFrameNames('jump', 0, 4, '', 2)
      10, false)

    @animations.add('fall',
      Phaser.Animation.generateFrameNames('jump', 3, 7, '', 2)
      10, false)

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

    @hurtAnim = @animations.add('hurt',
      Phaser.Animation.generateFrameNames('hurt', 0, 8, '', 2),
      30, false)

  update: ->
    @falling = @body.velocity.y > 200
    if @falling
      @animations.play('fall')
    @handleControl()

  handleControl: ->
    if @animations.getAnimation('hurt').isPlaying
      return
    # Simulate friction/air resistance
    if -0.1 < @body.velocity.x < 0.1
      @body.velocity.x = 0

    if @body.velocity.x > 0
      @body.velocity.x -= @body.velocity.x/10 unless @body.velocity.x is 0
    else
      @body.velocity.x += @body.velocity.x/-10 unless @body.velocity.x is 0

    # pretend acceleration
    if @cursors.left.isDown
      @goLeft(@speed * @cursors.left.getAccel(@t_for_fspeed))

    else if @cursors.right.isDown
      @goRight(@speed * @cursors.right.getAccel(@t_for_fspeed))
    else
      @idle()

    # Jump/minijump
    if @cursors.up.justPressed(300) and @body.touching.down
        @jump()
        @jumping = true
    if @jumping and not (@body.touching.down or @cursors.up.isDown)
      @body.velocity.y = Math.floor(@body.velocity.y/3)
      @jumping = false

  goLeft: ->
    super
    @body.offset.setTo(-5, 0);

  goRight: ->
    super
    @body.offset.setTo(5, 0);

  idle: ->
    if @body.touching.down and not @animations.getAnimation('hurt').isPlaying
      if @health > 5
          @animations.play('idle')
        else 
          @animations.play('exhausted')

  hurt: ->
    @health -= 4

  collideEnemy: (player, enemy) ->
    if not @invincible
      direction = if player.x > enemy.x then 1 else -1
      @body.velocity.y = -200
      @body.velocity.x = direction * 400
      @scale.setTo(-direction, 1)
      @animations.play('hurt')
      @health -= 1
      @invincible = true
      @game.time.events.add(
        @invincibleTime
        () -> @invincible = false
        @)
      @flash(@invincibleTime)
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
    # for i in [0..1]
    #   @sqots.add(new Sqot(@player, @game, @game.world.randomX, @game.world.randomY, 'sqot', 'walk00'))


    # Create some stars
    for i in [0..12]
      star = @stars.create(i * 70, 0, 'star')
      star.body.gravity.y = 6
      star.body.bounce.y = 0.7 + Math.random() * 0.2

  update: ->
    @game.physics.arcade.collide(@stars, @platforms);
    @game.physics.arcade.collide(@sqots, @platforms);
    @game.physics.arcade.overlap(
      @player, @sqots, @player.collideEnemy, Mob.canCollide, @player)
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

  Phaser.Key::getAccel = (maxTime) ->
      if @duration <= maxTime
        @duration / maxTime
      else
        1

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
    @game.world.setBounds(0, 0, 4000, 600)

    
    @player = new Player(@game, 32, @game.world.height - 150, 'serge', 'idle00')
    @snell = new Snell(@game, @player)

    @hud = new Hud(@game, @player)

    @snell.create()
    @player.create()
    @hud.create()

    @game.world.add(@player)
    @game.camera.follow(@player, Phaser.Camera.FOLLOW_TOPDOWN_TIGHT)

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

  render: ->
    # @game.debug.text("fps: #{@game.time.fps}", 16, 16)
    # @game.debug.text("falling: #{@player.falling}", 16, 32)
    # @game.debug.bodyInfo(@player, 16, 32)
    @game.debug.body(@player)

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